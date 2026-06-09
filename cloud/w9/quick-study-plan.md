# W9 Quick Study Plan — Hoàn thành 3 Day trong 1 đêm + 1 buổi sáng

> Mục tiêu: học nhanh nhưng vẫn hiểu đúng trọng tâm **Day A, Day B, Day C** của W9.
>
> Không học theo kiểu thuộc lòng. Học theo kiểu hiểu flow, biết tool nào làm gì, làm được lab mức cơ bản, trả lời được câu hỏi ôn tập.

---

## 0. Tổng quan cần nhớ trong 30 giây

W9 có 3 mảnh ghép chính:

```text
Day A — GitOps
  Git là source of truth
  ArgoCD sync manifest từ Git vào Kubernetes

Day B — Observability
  Prometheus/Grafana/Loki/OTel giúp biết app đang tốt hay xấu
  SLO/SLI/Burn Rate giúp đo chất lượng theo chuẩn SRE

Day C — Canary
  Argo Rollouts deploy version mới từ từ
  AnalysisTemplate query Prometheus
  Metric xấu thì auto-abort/rollback
```

Flow cuối cùng của cả tuần:

```text
Pull Request
  → CI validate manifest
  → Merge vào main
  → ArgoCD sync vào cluster
  → Argo Rollouts chạy canary
  → Prometheus đo metric
  → Grafana xem dashboard
  → Metric xấu thì canary auto-abort
```

---

## 1. Kế hoạch thời gian đề xuất

Nếu bắt đầu học vào buổi tối và cần xong trước sáng mai:

```text
Tối nay
  20:00 - 21:30   Day A — GitOps & CI/CD
  21:30 - 21:45   Nghỉ ngắn
  21:45 - 00:15   Day B — Observability phần core
  00:15 - 00:30   Tổng kết nhanh + commit/push nếu cần

Sáng mai
  07:30 - 09:30   Day C — Canary / Argo Rollouts
  09:30 - 10:00   Ôn 12 câu trọng tâm
  10:00 - 10:30   Check repo + reflection
```

Nếu bắt đầu trễ hơn, dùng bản rút gọn:

```text
Day A: 60 phút
Day B: 120 phút
Day C: 90 phút
Ôn tập: 30 phút
```

---

## 2. Nguyên tắc học deadline mode

- Không sa lầy cài tool quá 30 phút/lỗi.
- Nếu lab lỗi vì Docker/minikube/Helm, ghi lại lỗi và chuyển sang đọc hiểu flow.
- Ưu tiên hiểu **vì sao** trước, chạy được sau.
- Học theo checklist, không đọc lan man docs ngoài quá nhiều.
- Với mỗi day, chỉ cần nắm:
  1. Tool nào dùng để làm gì.
  2. Flow hoạt động thế nào.
  3. File YAML chính có field nào quan trọng.
  4. Kết quả cuối ngày là gì.

---

# DAY A — GitOps & CI/CD

## File cần đọc

```text
cloud/w9/day-a/README.md
cloud/w9/day-a/exercise-gitops-basics.md
```

## Mục tiêu trong 1 câu

> Đưa Kubernetes deployment từ thao tác tay bằng `kubectl apply` sang quản lý bằng Git và ArgoCD.

## Những ý bắt buộc phải hiểu

### 1. GitOps là gì?

GitOps là cách vận hành hệ thống trong đó **Git là source of truth**.

Nghĩa là trạng thái mong muốn của hệ thống nằm trong Git:

```text
Muốn đổi replica → sửa YAML trong Git
Muốn đổi image tag → sửa YAML trong Git
Muốn rollback → git revert commit lỗi
```

Không nên deploy chính thức bằng:

```bash
kubectl apply -f file.yaml
kubectl edit deployment my-app
kubectl set image deployment/my-app app=v2
```

Vì các lệnh đó làm cluster thay đổi ngoài Git.

---

### 2. CI/CD trong GitOps

CI kiểm tra thay đổi trước khi merge:

```text
Pull Request
  → validate YAML
  → check Kubernetes schema
  → review
```

CD trong GitOps không nhất thiết là GitHub Actions chạy `kubectl apply`.

CD trong GitOps là:

```text
Merge vào main
  → ArgoCD phát hiện Git thay đổi
  → ArgoCD sync manifest vào cluster
```

---

### 3. ArgoCD làm gì?

ArgoCD là GitOps controller.

Nó liên tục so sánh:

```text
Desired state = trạng thái trong Git
Actual state  = trạng thái thật trong Kubernetes
```

Nếu khác nhau:

```text
OutOfSync → Sync → Synced
```

Nếu có `selfHeal: true`, ai sửa tay trên cluster thì ArgoCD kéo lại đúng theo Git.

---

### 4. Rollback đúng GitOps

Rollback chuẩn:

```bash
git revert <bad-commit>
git push
```

ArgoCD sẽ sync commit revert vào cluster.

Không ưu tiên:

```bash
kubectl rollout undo deployment/my-app
```

Vì lệnh này rollback ngoài Git, dễ bị ArgoCD sync lại bản lỗi nếu Git chưa đổi.

---

## Lab Day A — Cần làm gì?

File lab:

```text
cloud/w9/day-a/exercise-gitops-basics.md
```

Ưu tiên thực hành:

1. Cài ArgoCD.
2. Tạo manifest app demo.
3. Tạo ArgoCD Application.
4. Test drift/self-healing bằng cách scale deployment tay.
5. Tạo GitHub Actions lint manifest.

Nếu không đủ thời gian, ít nhất đọc kỹ các phần:

- Bước 1: Cài ArgoCD
- Bước 4: Tạo ArgoCD Application
- Bước 5: Drift Detection & Self-Healing

## Câu hỏi ôn Day A

### Q1. GitOps là gì?

GitOps là phương pháp quản lý app/hạ tầng bằng Git, trong đó Git là source of truth và controller như ArgoCD tự đồng bộ trạng thái từ Git vào Kubernetes.

### Q2. ArgoCD làm gì?

ArgoCD theo dõi Git repo/path, so sánh desired state trong Git với actual state trong cluster, rồi sync cluster về đúng Git.

### Q3. Drift là gì?

Drift là khi trạng thái thực tế trong cluster khác trạng thái khai báo trong Git.

### Q4. Vì sao rollback nên dùng `git revert`?

Vì rollback bằng `git revert` giữ Git là source of truth, có lịch sử rõ ràng và ArgoCD sẽ sync trạng thái rollback vào cluster.

---

# DAY B — Observability / SLO / OTel

## File cần đọc

```text
cloud/w9/day-b/README.md
cloud/w9/day-b/exercise-observability-stack.md
```

## Mục tiêu trong 1 câu

> Biết hệ thống đang chạy tốt hay xấu bằng metrics, logs, traces, dashboard và alert.

## Những ý bắt buộc phải hiểu

### 1. Monitoring vs Observability

Monitoring trả lời:

```text
Hệ thống có đang chạy không?
```

Observability trả lời sâu hơn:

```text
Tại sao hệ thống chậm/lỗi?
Request lỗi ở service nào?
Metric nào xấu sau deploy?
```

---

### 2. Ba cột trụ Observability

```text
Metrics = số đo theo thời gian
Logs    = nhật ký sự kiện chi tiết
Traces  = đường đi của request qua nhiều service
```

Ví dụ:

- Metrics: request rate, error rate, latency p95/p99, CPU, memory.
- Logs: dòng lỗi stack trace, thông báo service failed.
- Traces: request đi qua API Gateway → Auth → Backend → DB.

---

### 3. Prometheus làm gì?

Prometheus lưu và query metrics dạng time-series.

Cơ chế chính:

```text
App expose /metrics
  → Prometheus scrape/pull metrics định kỳ
  → PromQL query metrics
  → Alertmanager/Grafana dùng dữ liệu đó
```

Query cần nhớ:

```promql
up
```

Kiểm tra target sống hay chết.

```promql
rate(http_requests_total[5m])
```

Tính tốc độ request trong 5 phút.

```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

Tính error rate HTTP 5xx.

---

### 4. Grafana làm gì?

Grafana dùng để vẽ dashboard từ data source như Prometheus và Loki.

Nó giúp nhìn:

- Request rate.
- Error rate.
- Latency.
- CPU/RAM.
- Logs theo namespace/pod.

---

### 5. Loki làm gì?

Loki là log aggregation system.

Trong Kubernetes:

```text
Pod logs
  → Promtail thu thập
  → Loki lưu logs
  → Grafana Explore query logs bằng LogQL
```

Query LogQL cơ bản:

```logql
{namespace="gitops-demo"}
```

---

### 6. OTel là gì?

OpenTelemetry là chuẩn chung để thu thập telemetry data: metrics, logs, traces.

OTel Collector hoạt động như trung gian:

```text
App dùng OTel SDK
  → gửi telemetry tới OTel Collector
  → Collector xử lý/batch/filter
  → export tới Prometheus/Loki/Jaeger/vendor khác
```

---

### 7. SLI / SLO / SLA

```text
SLI = Service Level Indicator
    = chỉ số đo được
    = ví dụ: tỷ lệ request thành công

SLO = Service Level Objective
    = mục tiêu chất lượng nội bộ
    = ví dụ: 99.9% request thành công trong 30 ngày

SLA = Service Level Agreement
    = cam kết pháp lý/kinh doanh với khách hàng
    = ví dụ: nếu uptime dưới mức cam kết thì đền tiền
```

---

### 8. Error Budget và Burn Rate

Nếu SLO = 99.9% thì Error Budget = 0.1%.

```text
Error Budget = phần được phép lỗi
Burn Rate = tốc độ đốt Error Budget
```

Burn rate cao nghĩa là hệ thống đang lỗi quá nhanh.

---

## Lab Day B — Cần làm gì?

File lab:

```text
cloud/w9/day-b/exercise-observability-stack.md
```

Ưu tiên thực hành:

1. Cài `kube-prometheus-stack`.
2. Port-forward Grafana.
3. Deploy app demo có `/metrics`.
4. Tạo ServiceMonitor.
5. Query Prometheus.
6. Cài Loki nếu còn thời gian.
7. Tạo PrometheusRule alert mẫu.

Nếu thiếu thời gian, ưu tiên Prometheus + Grafana trước, Loki/OTel đọc hiểu sau.

## Câu hỏi ôn Day B

### Q5. Metrics, logs, traces khác nhau thế nào?

Metrics là số đo theo thời gian, logs là dòng sự kiện chi tiết, traces là đường đi của một request qua nhiều service.

### Q6. Prometheus làm gì?

Prometheus scrape metrics từ app, lưu time-series và cho phép query bằng PromQL để làm dashboard hoặc alert.

### Q7. Grafana làm gì?

Grafana vẽ dashboard và hỗ trợ Explore dữ liệu từ Prometheus/Loki.

### Q8. SLO và SLI khác nhau thế nào?

SLI là chỉ số đo được, SLO là mục tiêu chất lượng đặt trên chỉ số đó.

### Q9. Burn rate là gì?

Burn rate là tốc độ hệ thống tiêu thụ error budget. Burn rate cao nghĩa là lỗi đang xảy ra quá nhanh so với mức cho phép.

---

# DAY C — Progressive Delivery / Canary

## File cần đọc

```text
cloud/w9/day-c/README.md
cloud/w9/day-c/exercise-canary-rollout.md
```

## Mục tiêu trong 1 câu

> Deploy version mới từ từ, đo metric sau mỗi bước, nếu metric xấu thì tự abort/rollback.

## Những ý bắt buộc phải hiểu

### 1. Progressive Delivery

Progressive Delivery là release từ từ thay vì đẩy 100% traffic ngay lập tức.

Các kiểu deploy:

```text
Recreate       = tắt cũ rồi bật mới, dễ downtime
RollingUpdate  = thay pod từ từ, nhưng ít kiểm soát traffic
Blue/Green     = chạy 2 môi trường cũ/mới rồi switch traffic
Canary         = cho một phần nhỏ traffic vào bản mới, đo metric, rồi tăng dần
```

Canary an toàn hơn vì nếu lỗi chỉ ảnh hưởng ít user.

---

### 2. ArgoCD vs Argo Rollouts

Không được nhầm 2 thằng này.

```text
ArgoCD
  → GitOps controller
  → Sync manifest từ Git vào cluster

Argo Rollouts
  → Progressive delivery controller
  → Quản lý canary/blue-green
  → Tăng traffic từng bước
  → Query metric để abort nếu xấu
```

---

### 3. Rollout CRD

Rollout giống Deployment nhưng có thêm strategy canary.

Ví dụ ý tưởng:

```yaml
strategy:
  canary:
    steps:
      - setWeight: 25
      - pause: { duration: 1m }
      - setWeight: 50
      - pause: { duration: 1m }
      - setWeight: 100
```

Nghĩa là:

```text
25% traffic/pod vào version mới
  → chờ 1 phút
  → nếu ổn tăng lên 50%
  → chờ 1 phút
  → nếu ổn lên 100%
```

---

### 4. AnalysisTemplate

AnalysisTemplate là nơi khai báo metric để kiểm tra canary.

Nó thường query Prometheus:

```yaml
metrics:
  - name: success-rate
    interval: 30s
    successCondition: result >= 0.99
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          <promql query>
```

Nếu metric pass → canary tiếp tục.

Nếu metric fail quá `failureLimit` → auto-abort.

---

### 5. Auto-abort

Auto-abort nghĩa là rollout tự dừng bản mới khi metric xấu.

Flow:

```text
Deploy version mới
  → setWeight 25%
  → AnalysisTemplate query Prometheus
  → result pass: tăng step tiếp theo
  → result fail: abort rollout
  → stable version tiếp tục phục vụ traffic
```

---

## Lab Day C — Cần làm gì?

File lab:

```text
cloud/w9/day-c/exercise-canary-rollout.md
```

Ưu tiên thực hành:

1. Cài Argo Rollouts controller.
2. Tạo Rollout YAML.
3. Tạo AnalysisTemplate.
4. Watch rollout bằng plugin.
5. Deploy image lỗi để test abort.

Nếu thiếu thời gian, phải hiểu được:

- `Rollout` thay thế `Deployment`.
- `strategy.canary.steps` điều khiển canary.
- `AnalysisTemplate` query Prometheus.
- Metric xấu thì abort.

## Câu hỏi ôn Day C

### Q10. Canary deployment là gì?

Canary deployment là chiến lược release version mới cho một phần nhỏ traffic trước, đo metric, nếu ổn thì tăng dần lên 100%, nếu lỗi thì rollback.

### Q11. Argo Rollouts khác ArgoCD thế nào?

ArgoCD sync manifest từ Git vào cluster. Argo Rollouts quản lý quá trình canary/blue-green và quyết định tăng traffic hoặc abort dựa trên metric.

### Q12. AnalysisTemplate dùng để làm gì?

AnalysisTemplate định nghĩa metric/query, thường từ Prometheus, để đánh giá canary version có đạt điều kiện hay không.

---

# 4. Checklist hoàn thành W9 nhanh

## Day A checklist

- [ ] Đọc `day-a/README.md`.
- [ ] Đọc/làm `day-a/exercise-gitops-basics.md`.
- [ ] Hiểu GitOps = Git source of truth.
- [ ] Hiểu ArgoCD Application.
- [ ] Hiểu drift/self-heal.
- [ ] Biết rollback bằng `git revert`.

## Day B checklist

- [ ] Đọc `day-b/README.md`.
- [ ] Đọc/làm `day-b/exercise-observability-stack.md`.
- [ ] Hiểu metrics/logs/traces.
- [ ] Hiểu Prometheus/Grafana/Loki/OTel.
- [ ] Hiểu SLI/SLO/Error Budget/Burn Rate.
- [ ] Query được hoặc đọc hiểu `up`, `rate`, error rate PromQL.

## Day C checklist

- [ ] Đọc `day-c/README.md`.
- [ ] Đọc/làm `day-c/exercise-canary-rollout.md`.
- [ ] Hiểu Progressive Delivery.
- [ ] Hiểu Canary.
- [ ] Hiểu Rollout CRD.
- [ ] Hiểu AnalysisTemplate.
- [ ] Hiểu auto-abort.

## Repo checklist

- [ ] Có file `cloud/w9/README.md`.
- [ ] Có file `cloud/w9/day-a/README.md`.
- [ ] Có file `cloud/w9/day-a/exercise-gitops-basics.md`.
- [ ] Có file `cloud/w9/day-b/README.md`.
- [ ] Có file `cloud/w9/day-b/exercise-observability-stack.md`.
- [ ] Có file `cloud/w9/day-c/README.md`.
- [ ] Có file `cloud/w9/day-c/exercise-canary-rollout.md`.
- [ ] Có file `cloud/w9/reflection.md`.
- [ ] Có file `cloud/w9/quick-study-plan.md`.

---

# 5. Bản ôn siêu ngắn trước test

Nếu chỉ còn 15 phút, học phần này.

## Day A

```text
GitOps = Git source of truth.
ArgoCD = controller sync Git → cluster.
Desired state = trạng thái trong Git.
Actual state = trạng thái thật trong cluster.
Drift = desired khác actual.
Self-heal = ArgoCD tự sửa cluster về đúng Git.
Rollback chuẩn = git revert.
```

## Day B

```text
Metrics = số đo.
Logs = sự kiện chi tiết.
Traces = đường đi request.
Prometheus = scrape/query metrics.
Grafana = dashboard.
Loki = logs.
OTel = chuẩn thu thập telemetry.
SLI = chỉ số đo.
SLO = mục tiêu chất lượng.
Error Budget = phần được phép lỗi.
Burn Rate = tốc độ đốt error budget.
```

## Day C

```text
Progressive Delivery = deploy từ từ.
Canary = đưa version mới tới ít traffic trước.
Argo Rollouts = controller quản lý canary.
Rollout = Deployment + strategy canary.
AnalysisTemplate = Prometheus query để đánh giá canary.
Auto-abort = metric xấu thì dừng rollout và rollback stable.
```

---

# 6. Cách trình bày khi bị hỏi miệng

Nếu mentor hỏi: "W9 học gì?" trả lời:

> W9 tập trung vào Deliver Smartly. Day A em học GitOps với ArgoCD để Git trở thành source of truth, tránh deploy tay bằng kubectl. Day B em học Observability gồm metrics, logs, traces với Prometheus, Grafana, Loki và OTel, kèm SLO/SLI và burn rate alert để đo chất lượng hệ thống. Day C em học Progressive Delivery với Argo Rollouts, dùng canary deployment và AnalysisTemplate query Prometheus để tự động abort nếu version mới làm metric xấu.

Nếu mentor hỏi: "Vì sao cần Observability trước Canary?" trả lời:

> Canary chỉ an toàn khi mình đo được version mới có tốt hay không. Observability cung cấp metrics như error rate, latency, success rate. Argo Rollouts dùng AnalysisTemplate query Prometheus để quyết định tiếp tục tăng traffic hay abort rollback.

Nếu mentor hỏi: "ArgoCD và Argo Rollouts khác gì?" trả lời:

> ArgoCD lo GitOps sync manifest từ Git vào cluster. Argo Rollouts lo chiến lược deploy như canary/blue-green, tăng traffic từng bước và dùng metric để abort khi lỗi.
