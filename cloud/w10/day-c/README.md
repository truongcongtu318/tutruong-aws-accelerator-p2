# W10 Day C — Platform Integration, Runbook & Cost Guard

## Mục tiêu học tập

Day C là ngày cuối cùng của self-study trong W10, tập trung vào việc tích hợp toàn bộ các thành phần đã học từ W8→W10 thành một nền tảng vận hành đồng bộ và ổn định.

Sau khi hoàn thành Day C, bạn cần nắm vững:

1. **Platform Bootstrap**: Cách tạo một bộ cấu hình trung tâm (ResourceQuota + LimitRange) để kiểm soát tài nguyên cho từng namespace và ngăn chặn lạm dụng tài nguyên cluster.
2. **Chaos Testing cơ bản**: Hiểu về Resilience Testing và cách simulate sự cố đơn giản trên Kubernetes để kiểm tra độ bền của platform.
3. **Incident Response Runbook**: Cách viết và sử dụng runbook chuẩn để xử lý sự cố bảo mật hoặc quá tải theo quy trình 6 bước (Detect → Triage → Contain → Eradicate → Recover → Post-mortem).
4. **Cost Guard**: Cách giám sát chi phí trên AWS sử dụng Cost Explorer và Cost Anomaly Detection để phát hiện các spikes bất thường về chi phí đám mây.

---

## 1. Platform Bootstrap — Quản lý Tài nguyên (Resource Quota & Limit Range)

Khi triển khai một nền tảng multi-tenant (nhiều team), không có sự kiểm soát tài nguyên, một pod (hoặc namespace) có thể tiêu thụ hết CPU/RAM của cluster và làm crash các ứng dụng khác.

Kubernetes cung cấp 2 cơ chế để quản lý tài nguyên ở cấp độ Object và Container:

### 🔹 ResourceQuota
Giới hạn **tổng tài nguyên tối đa** mà một namespace có thể sử dụng hoặc tổng số lượng tối đa của một object type (pods, services, secrets, configmaps...).
- `requests.cpu/memory`: Tổng CPU/RAM request của tất cả pod trong namespace.
- `limits.cpu/memory`: Tổng CPU/RAM limit của tất cả pod trong namespace.
- `count/pods`: Số lượng pod tối đa trong namespace.

### 🔹 LimitRange
Thiết lập **giá trị mặc định** (default), giới hạn tối thiểu (min), tối đa (max) cho **mỗi container riêng lẻ** trong namespace.
- Nếu developer quên khai báo `resources: { requests: ..., limits: ... }`, K8s sẽ tự động gán giá trị default/max.

---

## 2. Chaos Engineering — Kiểm thử Độ bền (Chaos Test)

Một platform hoàn chỉnh phải chịu được những sự kiện bất ngờ. **Chaos Engineering** là phương pháp chủ động tạo ra lỗi trong hệ thống để kiểm thử khả năng phục hồi.

Các bài test phổ biến:
1. **Pod Kill**: Xoá đột ngột các pod của một ứng dụng quan trọng và kiểm tra xem chúng có tự khởi tạo lại và hoạt động ổn định không.
2. **Node Drain**: Drain một node ra khỏi cluster để kiểm tra scheduler và quá trình tái cân bằng auto-scaling.
3. **Network Latency/Loss**: Inject độ trễ mạng vào traffic để kiểm tra timeout và retry logic của các service giao tiếp với nhau.

---

## 3. Incident Response Runbook — Xử lý sự cố theo quy trình

Runbook là tài liệu chuẩn hoá để người trực vận hành (SRE/DevOps) thực hiện các bước xử lý một cách nhanh chóng và đúng đắn khi xảy ra bất thường.

### Mô hình 6 bước IR (Incident Response):
| Bước | Tiếng Anh | Tiếng Việt | Mô tả |
|------|-----------|------------|-------|
| **1** | **Detect** | Phát hiện | Nhận cảnh báo từ monitoring (CloudWatch Alarm, Grafana Alert). |
| **2** | **Triage** | Phân loại | Xác định mức độ nghiêm trọng (P1/P2/P3), đối tượng bị ảnh hưởng, và nhóm phụ trách. |
| **3** | **Contain** | Khoanh vùng, cách ly | Ngăn sự cố lan rộng (cách ly pod, node, hoặc namespace bị ảnh hưởng). |
| **4** | **Eradicate** | Loại bỏ nguyên nhân gốc | Tìm và sửa nguyên nhân gốc rễ (upgrade image, vá lỗ hổng, xoá process độc hại). |
| **5** | **Recover** | Khôi phục dịch vụ | Restore dữ liệu, scale up app, kiểm tra traffic quay về bình thường. |
| **6** | **Post-mortem** | Rút kinh nghiệm | Viết báo cáo phân tích, cập nhật Runbook, tạo ticket hành động phòng ngừa. |

---

## 4. Cost Guard — AWS Cost Anomaly Detection

Sau khi xây dựng xong hệ thống, việc đảm bảo chi phí vận hành không vượt quá ngân sách là vô cùng quan trọng. AWS cung cấp **Cost Anomaly Detection** để tự động phát hiện các sự tăng đột biến về chi phí.

### Các thành phần của AWS Cost Anomaly Detection:
1. **Monitor**: Theo dõi một tập dịch vụ AWS cụ thể (ví dụ: EC2, EKS, RDS). Có thể đặt ngưỡng phát hiện (ví dụ: chi phí tăng > 20%).
2. **Alert Subscription**: Khi cost spike được phát hiện, gửi cảnh báo qua Email, SNS, Slack...

### Cost Guard trong K8s:
Kết hợp với `ResourceQuota` ở trên, ta đảm bảo các dev team chỉ dùng lượng tài nguyên được cấp, tránh lạm dụng gây tốn kém chi phí đám mây.

---

## Tài liệu đọc thêm
- [Kubernetes ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Kubernetes LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [AWS Cost Anomaly Detection](https://docs.aws.amazon.com/cost-management/latest/userguide/manage-ad.html)
- [Google SRE — Example Postmortem](https://sre.google/workbook/example-postmortem/)
- [LitmusChaos](https://litmuschaos.io/)
