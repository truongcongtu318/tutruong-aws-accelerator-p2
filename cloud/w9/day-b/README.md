# W9 Day B — Observability: SLO/SLI/OTel + Prometheus + Grafana + Loki

## Mục tiêu học

Day B tương ứng **T3 09/06**. Chủ đề chính là đưa platform từ trạng thái chạy mù (blind running) sang trạng thái **quan sát được** (observable) bằng các công cụ hiện đại: OpenTelemetry, Prometheus, Grafana, Loki.

Sau Day B, bạn cần nắm chắc:

1. **Observability** là gì và vì sao monitoring truyền thống không đủ.
2. 3 cột trụ (pillars) của Observability: **Metrics**, **Logs**, **Traces**.
3. **OpenTelemetry (OTel)** là gì: OTel SDK và OTel Collector.
4. **Prometheus** dùng để làm gì và cơ chế Pull-based metrics.
5. **Grafana** dùng làm dashboard trực quan hóa.
6. **Loki** dùng làm log aggregation.
7. Phương pháp luận **SLO/SLI** từ Google SRE.
8. Cơ chế cảnh báo **Multi-window burn rate alert**.

---

## 1. Observability là gì?

**Observability (Khả năng quan sát)** là khả năng suy luận trạng thái bên trong của hệ thống dựa trên thông tin đầu ra (outputs).

So sánh Monitoring vs Observability:

```text
Monitoring (Giám sát)
  → Hỏi: "Hệ thống có chạy không?"
  → Công cụ: Ping, CPU usage, RAM usage.
  → Đặc điểm: Biết khi nào lỗi, nhưng khó biết tại sao lỗi.

Observability (Quan sát)
  → Hỏi: "Tại sao hệ thống chạy chậm ở endpoint này đối với user này?"
  → Công cụ: Distributed Tracing, Logs, Metrics.
  → Đặc điểm: Tìm ra nguyên nhân gốc rễ (root cause) của hệ thống phân tán phức tạp.
```

---

## 2. Ba cột trụ của Observability

Hệ thống Observability hoàn chỉnh cần kết hợp cả 3 cột trụ:

```text
       Metrics (Hệ thống thế nào?)
     /        \
    /          \
Logs            Traces (Lỗi xảy ra ở đâu, luồng đi thế nào?)
(Chuyện gì xảy ra chi tiết?)
```

### Metrics (Số liệu giám sát)

- Là dữ liệu dạng số, có timestamp, thường có labels để group/filter.
- Rất nhẹ, lưu trữ rẻ.
- Ví dụ: `http_requests_total{method="GET", status="200"}`
- Dùng để làm dashboard tổng quan và bắn alert.

### Logs (Nhật ký)

- Là thông tin dạng text ghi lại sự kiện cụ thể của app.
- Nặng, lưu trữ đắt hơn metrics.
- Ví dụ: `2026-06-09T09:30:00Z INFO OrderService: Created order #12345`
- Dùng để debug chi tiết khi đã biết khoảng thời gian và component lỗi.

### Traces (Dấu vết phân tán)

- Theo dấu một request đi qua nhiều microservice khác nhau.
- Rất quan trọng trong hệ thống microservice để tìm bottle neck (nút thắt cổ chai).
- Ví dụ: Request đi qua `API Gateway (10ms) → Auth Service (5ms) → Order Service (100ms) → Database (80ms)`.

---

## 3. OpenTelemetry (OTel) là gì?

**OpenTelemetry (OTel)** là một chuẩn mã nguồn mở (vendor-neutral) do CNCF quản lý để thu thập metrics, logs, traces.

OTel giải quyết vấn đề: trước đây mỗi tool monitoring có một SDK riêng (ví dụ SDK của Prometheus khác SDK của Datadog). OTel cung cấp một chuẩn chung duy nhất cho ứng dụng, rồi từ đó gửi đi đâu cũng được.

### OTel SDK

- Thư viện nhúng trực tiếp vào source code ứng dụng (Python, Go, Java, Node...).
- Tự động (auto-instrumentation) hoặc tự viết tay (manual instrumentation) để sinh metrics/logs/traces.

### OTel Collector

- Là một proxy/agent nhận dữ liệu từ các app, xử lý (filter, batch, transform), rồi gửi (export) sang các storage backends như Prometheus, Jaeger, Loki.

Cơ chế hoạt động:

```text
App (OTel SDK)
     ↓
OTel Collector (Receive → Process → Export)
  ┌──┴───────────┐
  ↓              ↓
Prometheus     Loki
```

---

## 4. Prometheus

**Prometheus** là hệ thống monitor và alert nguồn mở. Nó lưu trữ dữ liệu dạng time-series.

### Cơ chế Pull-based

- Khác với nhiều monitor system gửi dữ liệu chủ động (Push), Prometheus chủ động đi kéo (Scrape/Pull) metrics từ các app.
- Các app phải có một endpoint (thường là `/metrics`) trả về dữ liệu đúng định dạng Prometheus.

Ví dụ định dạng Prometheus:

```text
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1043
http_requests_total{method="POST",status="500"} 12
```

### PromQL

PromQL (Prometheus Query Language) dùng để truy vấn dữ liệu.

Ví dụ:

- Tính throughput (request rate) trong 5 phút:
  `rate(http_requests_total[5m])`
- Tính tỷ lệ lỗi HTTP 5xx:
  `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))`

---

## 5. Grafana và Loki

### Grafana

- Công cụ visualize dữ liệu, vẽ biểu đồ dashboard.
- Grafana kết nối vào Prometheus làm data source để vẽ biểu đồ CPU/RAM, Request Rate, Latency.
- Kết nối vào Loki để xem log ngay trên dashboard.

### Loki

- Hệ thống log aggregation của Grafana Labs.
- Khác với Elasticsearch lưu index toàn bộ log message, Loki chỉ đánh index các labels (ví dụ: `app="backend"`, `env="prod"`).
- Nhờ vậy, Loki lưu log cực kỳ rẻ và nhanh, rất phù hợp với Kubernetes vì Kubernetes pod sinh log liên tục.
- Log được query qua ngôn ngữ **LogQL**.

---

## 6. SLO/SLI/SLA và SLO Methodology (Google SRE)

Để đánh giá hệ thống chạy tốt hay tệ, Google SRE đưa ra phương pháp luận:

```text
SLI (Service Level Indicator)   → Đo lường thế nào? (Chỉ số thực tế)
SLO (Service Level Objective)   → Đạt mục tiêu bao nhiêu? (Cam kết nội bộ)
SLA (Service Level Agreement)   → Đền bù bao nhiêu nếu tạch? (Cam kết với khách hàng)
```

Ví dụ:

- **SLI**: Tỷ lệ HTTP request thành công (không phải 5xx) trong 5 phút.
- **SLO**: SLI phải $\ge$ 99.9% tính trong chu kỳ 30 ngày.
- **SLA**: Nếu SLO < 99.0%, đền tiền cho khách hàng.

### Error Budget (Ngân sách lỗi)

Error Budget = 100% - SLO.

Nếu SLO là 99.9%, thì Error Budget là 0.1%.

```text
Error Budget
  → Là quyền được lỗi của hệ thống.
  → Dùng để cân bằng giữa tốc độ release tính năng mới và độ ổn định.
  → Nếu còn Error Budget: có thể deploy tính năng mới nhanh.
  → Nếu hết Error Budget: đóng băng deploy, tập trung sửa bug/ổn định hệ thống.
```

---

## 7. Multi-window burn rate alert

**Burn Rate** là tốc độ tiêu thụ Error Budget.

- Burn Rate = 1: Tiêu thụ hết Error Budget vừa đúng chu kỳ (ví dụ 30 ngày).
- Burn Rate = 2: Tiêu thụ hết Error Budget nhanh gấp đôi (15 ngày).
- Burn Rate = 14.4: Tiêu thụ hết Error Budget trong 50 giờ (tiêu 2% budget trong 1 giờ).

Cảnh báo theo kiểu truyền thống (ví dụ: `CPU > 80% trong 5m`) rất dễ bị báo động giả (alert fatigue). SRE khuyến nghị dùng **Multi-window Multi-burn-rate Alerting** để báo động chính xác.

Google khuyến nghị dùng 2 cửa sổ (window) để lọc nhiễu:

| Loại Alert | Cửa sổ nhanh (Fast window) | Cửa sổ chậm (Slow window) | Burn Rate | Ý nghĩa |
|---|---|---|---|---|
| **Critical** | 1 giờ | 6 giờ | 14.4 | Mất 2% budget trong 1h, báo ngay lập tức |
| **Warning** | 6 giờ | 30 giờ | 6 | Mất 5% budget trong 6h, báo qua ticket/slack |

Ví dụ rule Prometheus Alertmanager:

```yaml
groups:
  - name: app-slo-alerts
    rules:
      - alert: AppErrorBudgetBurnRateFast
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1h])) 
            / 
            sum(rate(http_requests_total[1h]))
          ) > (1 - 0.999) * 14.4
          and
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) 
            / 
            sum(rate(http_requests_total[5m]))
          ) > (1 - 0.999) * 14.4
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast burn rate detected on App SLO (Error Budget consuming fast)"
```

Giải thích: Rule chỉ kích hoạt khi cả trung bình 1 giờ (fast) và 5 phút (slow window tương ứng) đều vượt ngưỡng burn rate 14.4. Cách này triệt tiêu hoàn toàn trường hợp lag nhẹ 1-2 giây làm bắn alert khẩn cấp giữa đêm.

---

## 8. Cấu trúc thư mục đề xuất Day B

```text
cloud/w9/day-b/
  README.md
  otel/
    collector-config.yaml
  dashboards/
    app-dashboard.json
  alert-rules/
    slo-alerts.yaml
```

---

## 9. Checklist Day B

### Observability basics

- [ ] Phân biệt Monitoring vs Observability.
- [ ] Hiểu 3 cột trụ Metrics, Logs, Traces.
- [ ] Biết OTel Collector làm nhiệm vụ gì.

### Metrics & Prometheus

- [ ] Hiểu cơ chế pull/scrape metrics.
- [ ] Biết viết PromQL cơ bản để tính tỷ lệ lỗi và latency.
- [ ] Biết config `/metrics` endpoint cho app.

### Logs & Loki

- [ ] Biết Loki khác Elasticsearch ở chỗ nào.
- [ ] Viết được LogQL cơ bản để filter log theo label.

### SLO & Alerting

- [ ] Phân biệt SLI, SLO, SLA.
- [ ] Tính được Error Budget từ SLO.
- [ ] Hiểu Burn Rate là gì.
- [ ] Giải thích được lợi ích của Multi-window burn rate alert.

---

## 10. Kết quả mong muốn cuối Day B

Cuối Day B, bạn cần:

1. Đưa được OTel Collector/Prometheus/Grafana/Loki lên cluster minikube.
2. Có dashboard Grafana hiển thị: Request Rate, Latency (p99/p95), Error Rate (Golden Signals).
3. Viết được rule alert burn rate theo SLO.
4. Tách log của container vào Loki và xem được trên Grafana.

Deliverable tối thiểu:

```text
cloud/w9/day-b/
  README.md
  otel/collector-config.yaml
  alert-rules/slo-alerts.yaml
```
