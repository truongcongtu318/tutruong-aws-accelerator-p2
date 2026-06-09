# W9 Day C — Thực hành Canary với Argo Rollouts và Prometheus Analysis

Lab này hướng dẫn cài đặt Argo Rollouts controller, đổi cấu hình ứng dụng từ `Deployment` sang `Rollout`, thực hiện canary release và cấu hình AnalysisTemplate tự động kiểm tra Prometheus metric để abort nếu lỗi.

## 🎯 Mục tiêu bài lab
1. Cài đặt Argo Rollouts controller lên cluster minikube.
2. Cài đặt Argo Rollouts kubectl plugin để theo dõi tiến độ.
3. Chuyển đổi ứng dụng demo sang dùng CRD `Rollout`.
4. Tạo `AnalysisTemplate` đo tỉ lệ lỗi của app.
5. Deploy canary phiên bản lỗi để xem cơ chế **auto-abort** và rollback tự động.

---

## 🛠️ Chuẩn bị môi trường
- Đã hoàn thành các bước của **Day A** (ArgoCD) và **Day B** (Prometheus).
- Cần có repo Git và namespace app `observability-demo`.

---

## 🚀 Các bước thực hiện

### Bước 1: Cài đặt Argo Rollouts Controller
Chạy lệnh tạo namespace và apply manifest cài đặt chính thức:

```bash
# Tạo namespace riêng cho Argo Rollouts
kubectl create namespace argo-rollouts

# Cài đặt controller
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

Chờ pod chuyển sang trạng thái `Running`:
```bash
kubectl get pods -n argo-rollouts
```

---

### Bước 2: Cài đặt Argo Rollouts Kubectl Plugin
Để tiện theo dõi rollout qua CLI (dành cho Linux/Git-bash):

```bash
# Tải plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64

# Chuyển quyền thực thi
chmod +x ./kubectl-argo-rollouts-linux-amd64

# Di chuyển vào PATH
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

Kiểm tra plugin hoạt động:
```bash
kubectl argo rollouts version
```

---

### Bước 3: Đổi Deployment thành Rollout
Tạo một file mới `rollout.yaml` thay thế cho deployment của Day B.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: canary-demo-app
  namespace: observability-demo
spec:
  replicas: 4
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: canary-demo-app
  template:
    metadata:
      labels:
        app: canary-demo-app
    spec:
      containers:
        - name: app
          image: quay.io/brancz/prometheus-example-app:v0.5.0
          ports:
            - name: web
              containerPort: 8080
  strategy:
    canary:
      # Chúng ta chia làm 3 bước
      steps:
        - setWeight: 25
        - pause: { duration: 1m }
        - setWeight: 50
        - pause: { duration: 1m }
        - setWeight: 100
      analysis:
        templates:
          - templateName: canary-analysis
        startingStep: 1 # Bắt đầu test metric ngay từ step 1
```

Tạo service cho Rollout (cần có stable service và canary service):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: canary-demo-app-stable
  namespace: observability-demo
spec:
  selector:
    app: canary-demo-app
  ports:
    - name: web
      port: 8080
      targetPort: 8080
```

Apply cả 2 file trên:
```bash
kubectl apply -f rollout.yaml
```

---

### Bước 4: Tạo AnalysisTemplate liên kết Prometheus
Tạo file `analysis.yaml` mô tả cách kiểm tra Prometheus metric. Để đơn giản ở local, chúng ta sẽ viết query kiểm tra xem app target có bị sập hoàn toàn (`up == 0`) không:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-analysis
  namespace: observability-demo
spec:
  metrics:
    - name: check-app-up
      interval: 10s
      successCondition: result[0] == 1
      failureLimit: 1
      provider:
        prometheus:
          address: http://monitoring-kube-prometheus-prometheus.monitoring:9090
          query: |
            up{namespace="observability-demo", pod=~"canary-demo-app-.*"}
```

Apply file analysis:
```bash
kubectl apply -f analysis.yaml
```

---

### Bước 5: Xem quá trình Deploy Canary
Chạy dashboard terminal để theo dõi:

```bash
kubectl argo rollouts get rollout canary-demo-app -n observability-demo --watch
```

Bây giờ hãy trigger thay đổi bằng cách thay đổi image/config của Rollout sang phiên bản mới:

```bash
kubectl argo rollouts set image canary-demo-app app=quay.io/brancz/prometheus-example-app:v0.5.0 -n observability-demo
```
*(Lưu ý: Do ta set trùng tag hoặc chỉnh sửa tag sang tag khác như `:latest` hoặc tag bất kì để trigger rollout).*

Bạn sẽ thấy ở giao diện terminal, 1 pod canary mới được tạo, chiếm 25% (1/4 pod).
Quá trình check metric sẽ diễn ra sau khi pod canary start.

---

### Bước 6: Giả lập Sự cố để Test Auto-Abort
Để giả lập việc Canary lỗi khiến metric sập và tự động rollback:

1. Deploy version mang nhãn lỗi hoặc scale down Prometheus để query thất bại.
2. Hoặc dễ nhất, deploy một image sai hoàn toàn (không tồn tại/crashloop):
   ```bash
   kubectl argo rollouts set image canary-demo-app app=quay.io/brancz/prometheus-example-app:v99.9.9 -n observability-demo
   ```
3. Xem màn hình `--watch`:
   - Pod canary mới ở trạng thái lỗi (`ErrImagePull` hoặc crash).
   - Prometheus query trả về kết quả fail (hoặc data trống không thoả mãn `result[0] == 1`).
   - Argo Rollouts lập tức phát hiện số lần failure vượt quá `failureLimit: 1`.
   - Controller tự động abort đợt deploy này, đánh dấu trạng thái là `Degraded` rồi đưa traffic trở về 100% stable pod cũ.
   - Pod lỗi bị xoá bỏ hoàn toàn.

---

## 📝 Kết quả cần đạt
- [ ] Cài đặt thành công Argo Rollouts controller.
- [ ] Sử dụng được lệnh `kubectl argo rollouts` và plugin CLI.
- [ ] Đổi được Deployment thông thường thành Rollout.
- [ ] Cấu hình thành công `AnalysisTemplate` truy vấn từ Prometheus.
- [ ] Chứng kiến tận mắt quá trình deploy tự dừng (abort) và rollback hoàn toàn tự động khi deploy image lỗi.
