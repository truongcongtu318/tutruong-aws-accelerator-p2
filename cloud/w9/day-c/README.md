# W9 Day C — Progressive Delivery (Canary) với Argo Rollouts

## Mục tiêu học

Day C tương ứng **T4 10/06**. Chủ đề chính là triển khai canary deployment tự động rollback khi phát hiện metric xấu — kết hợp với burn rate alert của Day B.

Sau Day C, bạn cần nắm chắc:

1. **Progressive Delivery** là gì và tại sao Blue/Green + Canary là best practice.
2. **Argo Rollouts** là gì và cách nó thay thế `Deployment` K8s.
3. **Rollout CRD** — khai báo canary với từng bước (step) tăng traffic.
4. **AnalysisTemplate** — cấu hình metrics query đánh giá canary có pass không.
5. Cơ chế **auto-abort** khi metric xấu.
6. Kết hợp canary với **Prometheus query** và burn rate alert.

---

## 1. Progressive Delivery là gì?

**Progressive Delivery** là chiến lược triển khai từ từ phiên bản mới ra một phần user trước, kiểm tra chất lượng, nếu ổn mới lan rộng hơn.

So sánh chiến lược deploy:

```text
Recreate: Xoá hết cũ → tạo hết mới → Downtime.

Rolling update: Từ từ cập nhật từng pod, nhưng không kiểm soát traffic.

Blue/Green: Chạy song song bản mới (Green) bên cạnh bản cũ (Blue),
           chuyển hết traffic sang Green khi sẵn sàng.

Canary: Chạy song song 2 bản, gửi 1 phần nhỏ traffic vào bản mới,
        đo lường, nếu ổn thì tăng dần đến 100%.
```

Canary là tốt nhất vì:

- Rủi ro thấp: lỗi chỉ ảnh hưởng tới 5-10% user.
- Có thời gian đo lường: cho phép Prometheus/OTel đánh giá.
- Auto-abort: nếu metric xấu thì tự dừng, không cần người trực.

---

## 2. Argo Rollouts là gì?

**Argo Rollouts** là controller cho Kubernetes hỗ trợ Blue/Green và Canary deployment.

ArgoCD không có sẵn logic canary. ArgoCD chỉ quản lý manifest. Argo Rollouts là controller riêng, được cài vào cluster để xử lý Rollout resource (thay vì Deployment truyền thống).

```text
ArgoCD: Sync Git → Cluster (quản lý phiên bản, chống drift)
Argo Rollouts: Quyết định tỷ lệ traffic mới/cũ dựa trên metrics (canary logic)
```

Visual:

```text
ArgoCD đẩy Rollout resource vào cluster
        ↓
Argo Rollouts controller đọc Rollout CRD
        ↓
Controller tạo ReplicaSet mới (canary) + ReplicaSet cũ (stable)
        ↓
Controller tăng % canary từng bước (step)
        ↓
Sau mỗi bước, chạy AnalysisRun query Prometheus
        ↓
Nếu metric ổn → tăng lên step tiếp theo
Nếu metric xấu → abort → rollback về stable
```

---

## 3. Rollout CRD — Cấu trúc cơ bản

Dưới đây là Rollout tương tự Deployment, nhưng có thêm `strategy.canary`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: demo-app-rollout
  namespace: demo
spec:
  replicas: 5
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: demo-app
          image: nginx:1.25
          ports:
            - containerPort: 80
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 2m }
        - setWeight: 30
        - pause: { duration: 2m }
        - setWeight: 60
        - pause: { duration: 2m }
        - setWeight: 100
      analysis:
        templates:
          - templateName: demo-app-analysis
        startingStep: 1
```

Giải thích các bước:

| Step | Mô tả |
|---|---|
| `setWeight: 10` | Đưa 10% traffic vào phiên bản mới (canary) |
| `pause: {duration: 2m}` | Chờ 2 phút để metrics/cảnh báo kịp phát hiện |
| `setWeight: 30` | Tăng lên 30% |
| `pause: {duration: 2m}` | Chờ thêm 2 phút |
| `setWeight: 60` | 60% |
| `setWeight: 100` | 100% → canary xong, stable = mới |

---

## 4. AnalysisTemplate với Prometheus query

**AnalysisTemplate** định nghĩa các metric/query và điều kiện pass/fail.

Ví dụ kiểm tra tỷ lệ lỗi:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: demo-app-analysis
  namespace: demo
spec:
  metrics:
    - name: success-rate
      interval: 30s
      successCondition: result >= 0.99
      failureLimit: 3
      provider:
        prometheus:
          address: http://prometheus-server.monitoring:9090
          query: |
            sum(rate(http_requests_total{namespace="demo",status=~"2..|3.."}[1m]))
            /
            sum(rate(http_requests_total{namespace="demo"}[1m]))
```

Giải thích:

| Field | Ý nghĩa |
|---|---|
| `interval` | Prometheus query mỗi 30 giây |
| `successCondition` | Nếu tỷ lệ thành công ≥ 99% thì pass |
| `failureLimit` | Chỉ cần 3 lần fail là abort |
| `provider.prometheus.query` | PromQL query tính tỷ lệ thành công |

Quy trình:

```text
Mỗi 30 giây Argo Rollouts gọi Prometheus.
Nếu result >= 0.99 (99% request thành công): pass, tiếp tục canary.
Nếu result < 0.99: fail → đếm lên.
Sau 3 lần fail: ABORT → rollback về stable.
```

---

## 5. Auto-abort cơ chế

Argo Rollouts có 2 kiểu auto-abort:

### a) Abort khi AnalysisTemplate fail

Khi query Prometheus không pass sau số lần chịu đựng (failureLimit), Rollout tự abort:

```text
AnalysisRun: FAIL → Rollout -> Aborted
    ├── canary scaled to 0 replicas
    └── previous stable trở lại 100% traffic
```

### b) Abort từ controller khi canary service không healthy

Argo Rollouts cũng kiểm tra pod health bằng cách chạy readiness probe. Nếu canary pod không start/handshake thành công, controller không tăng step.

---

## 6. Kết hợp Canary với Burn Rate Alert

Day B học burn rate alert: cảnh báo phát ra trong 1-2 phút khi error budget bị xài quá nhanh.

Day C, canary auto-abort dựa trên Prometheus query của AnalysisTemplate. Ta có thể kết hợp:

```yaml
metrics:
  - name: error-budget-burn-rate
    interval: 30s
    successCondition: result < 14.4   # Burn rate dưới 14.4 là ok
    failureLimit: 2
    provider:
      prometheus:
        address: http://prometheus-server.monitoring:9090
        query: |
          (
            sum(rate(http_requests_total{namespace="demo",status=~"5.."}[1h]))
            /
            sum(rate(http_requests_total{namespace="demo"}[1h]))
          )
          /
          (1 - 0.999)
```

Điều này đảm bảo:

```text
slo-alerts.yaml (Cảnh báo on-call)
  → Giống như canary auto-abort
  → Nhưng alert là để gửi vào Slack khi canary tự abort rồi

Rollout abort (Action)
  → Tránh deploy xấu
  → Không cần người trực vì đã có auto-abort từ Argo Rollouts
```

---

## 7. Cấu trúc thư mục đề xuất Day C

```text
cloud/w9/day-c/
  README.md
  rollout/
    rollout.yaml
    analysis-template.yaml
  service/
    canary-service.yaml
    stable-service.yaml
```

---

## 8. Checklist Day C

### Progressive Delivery concepts

- [ ] Phân biệt Recreate, Rolling, Blue/Green, Canary.
- [ ] Hiểu vì sao canary là low-risk deployment.

### Argo Rollouts

- [ ] Biết Rollout thay thế Deployment trong canary.
- [ ] Hiểu `setWeight` + `pause` trong canary step.
- [ ] Viết được Rollout yaml cơ bản.

### AnalysisTemplate

- [ ] Viết được AnalysisTemplate với Prometheus provider.
- [ ] Hiểu `successCondition` và `failureLimit`.
- [ ] Biết arithmetic query trong PromQL.

### Auto-abort

- [ ] Hiểu cơ chế auto-abort từ AnalysisTemplate.
- [ ] Biết kết hợp canary với burn rate metric.

---

## 9. Kết quả mong muốn cuối Day C

Cuối ngày (trước Online Test 2), bạn cần:

1. Có Rollout YAML cho demo app với canary steps (10% → 2m → 30% → 2m → 100%).
2. Có AnalysisTemplate đo tỷ lệ lỗi (error rate) hoặc burn rate.
3. Rollout auto-abort khi deploy version có bug hoặc latency xấu.
4. Giải thích được lưu đồ canary: setWeight → AnalysisRun → pass/fail → next step/abort.

Deliverable tối thiểu:

```text
cloud/w9/day-c/
  README.md
  rollout/rollout.yaml
  rollout/analysis-template.yaml
```
