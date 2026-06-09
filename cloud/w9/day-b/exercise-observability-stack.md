# W9 Day B — Thực hành Observability Stack với Prometheus, Grafana, Loki và OTel

Lab này giúp bạn dựng một stack observability cơ bản trên Kubernetes local để theo dõi ứng dụng demo.

## 🎯 Mục tiêu bài lab
1. Cài đặt Prometheus và Grafana bằng Helm.
2. Cài đặt Loki để thu thập log từ pod.
3. Tạo dashboard Grafana cơ bản quan sát CPU, memory, request rate, error rate.
4. Viết rule cảnh báo SLO/Burn Rate mẫu.
5. Hiểu cách OpenTelemetry Collector đứng giữa app và backend observability.

---

## 🛠️ Chuẩn bị môi trường

Cần có:

```bash
kubectl version --client
minikube status
helm version
```

Nếu chưa có Helm, cài theo docs: https://helm.sh/docs/intro/install/

Tạo namespace monitoring:

```bash
kubectl create namespace monitoring
```

---

## 🚀 Phần 1 — Cài Prometheus + Grafana

Cài stack phổ biến `kube-prometheus-stack`:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

Kiểm tra pod:

```bash
kubectl get pods -n monitoring
```

Bạn sẽ thấy các component như:

```text
prometheus-operator
prometheus-monitoring-kube-prometheus-prometheus-0
grafana
alertmanager
kube-state-metrics
node-exporter
```

---

## 🚀 Phần 2 — Truy cập Grafana

Lấy password admin của Grafana:

```bash
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

Port-forward Grafana:

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Mở trình duyệt:

```text
http://localhost:3000
```

Đăng nhập:

```text
Username: admin
Password: <password lấy từ secret>
```

---

## 🚀 Phần 3 — Cài Loki để xem logs

Thêm Helm repo Grafana:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Cài Loki stack:

```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true
```

Kiểm tra:

```bash
kubectl get pods -n monitoring | grep loki
kubectl get pods -n monitoring | grep promtail
```

Trong Grafana, thêm data source Loki:

```text
Connections → Data sources → Add data source → Loki
URL: http://loki:3100
Save & test
```

Sau đó vào Explore, chọn Loki và query thử:

```logql
{namespace="gitops-demo"}
```

---

## 🚀 Phần 4 — Tạo app demo sinh metrics

Nếu Day A đã có app nginx đơn giản, bạn có thể xem metrics hạ tầng của pod trước. Nếu muốn app có `/metrics` thật, dùng app mẫu `prometheus-example-app`.

Tạo file `demo-metrics-app.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: observability-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-example-app
  namespace: observability-demo
  labels:
    app: prometheus-example-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prometheus-example-app
  template:
    metadata:
      labels:
        app: prometheus-example-app
    spec:
      containers:
        - name: app
          image: quay.io/brancz/prometheus-example-app:v0.5.0
          ports:
            - name: web
              containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-example-app
  namespace: observability-demo
  labels:
    app: prometheus-example-app
spec:
  selector:
    app: prometheus-example-app
  ports:
    - name: web
      port: 8080
      targetPort: 8080
```

Apply:

```bash
kubectl apply -f demo-metrics-app.yaml
```

---

## 🚀 Phần 5 — Tạo ServiceMonitor cho Prometheus scrape app

`kube-prometheus-stack` dùng CRD `ServiceMonitor` để Prometheus biết cần scrape service nào.

Tạo file `service-monitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: prometheus-example-app
  namespace: monitoring
  labels:
    release: monitoring
spec:
  namespaceSelector:
    matchNames:
      - observability-demo
  selector:
    matchLabels:
      app: prometheus-example-app
  endpoints:
    - port: web
      path: /metrics
      interval: 15s
```

Apply:

```bash
kubectl apply -f service-monitor.yaml
```

Port-forward Prometheus để query:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

Mở:

```text
http://localhost:9090
```

Query thử:

```promql
up{namespace="observability-demo"}
```

---

## 🚀 Phần 6 — Viết alert rule SLO/Error Rate

Tạo file `slo-alert-rule.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: demo-slo-alerts
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
    - name: demo-slo.rules
      rules:
        - alert: DemoAppDown
          expr: up{namespace="observability-demo"} == 0
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Demo app target is down"
            description: "Prometheus cannot scrape demo app for more than 2 minutes."
```

Apply:

```bash
kubectl apply -f slo-alert-rule.yaml
```

Kiểm tra trong Prometheus UI:

```text
Status → Rules
Alerts
```

---

## 🚀 Phần 7 — OTel Collector concept config

Trong lab local, nếu app chưa instrument OTel thì chưa cần chạy thật. Nhưng cần hiểu config collector cơ bản.

Tạo file `otel-collector-config.yaml` để lưu lại concept:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  logging:
    verbosity: detailed

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus, logging]
```

Ý nghĩa:

```text
App gửi OTLP metrics/traces/logs
  → OTel Collector nhận ở receiver otlp
  → batch processor gom dữ liệu
  → exporter gửi ra Prometheus endpoint hoặc log debug
```

---

## 📝 Kết quả cần đạt

- [ ] Cài được `kube-prometheus-stack`.
- [ ] Truy cập được Grafana UI.
- [ ] Truy cập được Prometheus UI.
- [ ] Cài được Loki/Promtail và query log trong Grafana.
- [ ] Deploy app demo có endpoint `/metrics`.
- [ ] Prometheus scrape được app qua `ServiceMonitor`.
- [ ] Tạo được `PrometheusRule` cảnh báo app down.
- [ ] Hiểu vai trò của OTel Collector trong pipeline observability.

---

## 🧹 Cleanup

Nếu muốn xoá toàn bộ lab:

```bash
kubectl delete namespace observability-demo
helm uninstall monitoring -n monitoring
helm uninstall loki -n monitoring
kubectl delete namespace monitoring
```
