# W9 Reflection — Deliver Smartly

## 1. Điều tôi hiểu sau W9

Sau W9, tôi hiểu rằng chạy được app trên Kubernetes chưa đủ. Một platform tốt cần có quy trình delivery an toàn:

- Git là source of truth.
- ArgoCD tự sync trạng thái từ Git vào cluster.
- Observability giúp biết app đang tốt hay xấu.
- Canary deployment giúp giảm rủi ro khi release version mới.
- Metrics/SLO/Burn Rate có thể được dùng để tự động abort deploy xấu.

---

## 2. GitOps thay đổi cách deploy như thế nào?

Trước GitOps, tôi có thể dùng `kubectl apply` trực tiếp. Cách này nhanh nhưng khó kiểm soát.

Sau GitOps, workflow tốt hơn là:

```text
Sửa manifest trong Git
  → mở Pull Request
  → CI validate
  → review
  → merge
  → ArgoCD sync vào cluster
```

Lợi ích lớn nhất là mọi thay đổi đều có lịch sử, có review và rollback được bằng Git.

---

## 3. Observability giúp gì cho delivery?

Observability giúp trả lời câu hỏi: deploy mới có làm hệ thống tệ hơn không?

Các tín hiệu quan trọng:

- Request rate
- Error rate
- Latency p95/p99
- Logs lỗi
- Traces giữa các service

Nếu không có observability, canary chỉ là deploy từ từ nhưng không biết có an toàn thật không.

---

## 4. Canary và auto-abort

Canary deployment giúp đưa version mới tới một phần nhỏ traffic trước. Nếu metric tốt thì tăng dần traffic. Nếu metric xấu thì abort.

Tôi hiểu luồng canary như sau:

```text
Deploy version mới
  → gửi 10% traffic
  → query Prometheus
  → metric tốt: tăng lên 30%
  → metric xấu: abort và rollback về stable
```

---

## 5. Điều cần luyện thêm

- Viết PromQL tốt hơn.
- Hiểu rõ cách tính burn rate.
- Thực hành ArgoCD app-of-apps.
- Thực hành Argo Rollouts với traffic thật.
- Tích hợp dashboard Grafana để show-and-tell rõ hơn.
