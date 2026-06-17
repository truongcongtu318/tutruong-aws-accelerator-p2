# 🚨 Incident Response Runbook — W10 Template
# ======================================================
# Dùng để xử lý sự cố bảo mật hoặc sự cố K8s Platform.
# Copy file này khi có sự cố, điền thông tin theo các section.

---

## 🔴 SỰ CỐ: [TÊN NGẮN SỰ CỐ]

- **Incident ID**: INC-$(date +%Y%m%d)-XXXX
- **Phát hiện lúc**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Phát hiện bởi**: [Tên người / Tên alert]
- **Mức độ**: P1 / P2 / P3
- **Service/Namespace ảnh hưởng**: [Tên]
- **Trạng thái hiện tại**: [OPEN / CONTAINED / RESOLVED / CLOSED]

---

## Bước 1 — DETECT (Phát hiện)

Cảnh báo nhận được từ đâu?
- [ ] CloudWatch Alarm
- [ ] Grafana Alert
- [ ] Slack/ChatOps
- [ ] User report
- [ ] RBAC audit log bất thường

Mô tả triệu chứng:
```
Issue: [VD: deploy failed / pod crashloop / node draining suddenly / secret missing / pod privileged không rõ nguồn gốc]
```

---

## Bước 2 — TRIAGE (Phân loại & Đánh giá)

### 🔍 Mức độ ảnh hưởng:
- [ ] Production cluster chạy critical app (P1)
- [ ] Staging cluster (P2)
- [ ] Dev cluster (P3)

### 🔍 Xác định phạm vi:
- Namespace: [tên]
- Số pod bị ảnh hưởng: [con số]
- Service upstream/downstream: [tên]

---

## Bước 3 — CONTAIN (Khoanh vùng & Cách ly)

### Các hành động cần thực hiện ngay:

**1. Cách ly Pod/Namespace (nếu có pod độc hại):**
```bash
# Đánh taint node để không schedule pod khác vào (nếu node bị compromise)
kubectl taint nodes <node-name> compromised=true:NoExecute

# Cô lập namespace (thêm label và cấm ingress)
kubectl label namespace <namespace> security=isolated

# Network policy chặn toàn bộ traffic ra/vào namespace
```

**2. Snapshot node bị ảnh hưởng:**
```bash
# Capture logs
kubectl describe pod <suspicious-pod> -n <namespace> > describe-pod-$(date +%s).log
kubectl logs <suspicious-pod> -n <namespace> > pod-logs-$(date +%s).log
```

---

## Bước 4 — ERADICATE (Loại bỏ nguyên nhân gốc)

- [ ] Kiểm tra audit log của API server để xác định ai đã deploy/tạo resource
  ```bash
  kubectl get events -n <namespace> --sort-by=.lastTimestamp
  ```
- [ ] Nếu là lỗi CVE: update image lên bản patch mới, thông báo exception policy
- [ ] Nếu là lỗi RBAC: rút quyền của user/service account đó ngay lập tức
- [ ] Nếu là lỗi secrets: xoay vòng secret (update trên AWS Secrets Manager, đợi ESO sync)
- [ ] Nếu là lỗi admission: update constraint/policy

---

## Bước 5 — RECOVER (Khôi phục)

- [ ] Cập nhật image/rollback deployment
  ```bash
  kubectl rollout undo deployment/<name> -n <namespace>
  ```
- [ ] Xoá taint cách ly
  ```bash
  kubectl taint nodes <node-name> compromised-
  ```
- [ ] Xoá label namespace cách ly
- [ ] Kiểm tra service vẫn health
  ```bash
  kubectl get pods -n <namespace> -o wide
  kubectl get svc -n <namespace>
  ```
- [ ] Thông báo cho team qua Slack/Email về việc đã khôi phục

---

## Bước 6 — POST-MORTEM (Rút kinh nghiệm)

### Session Info:
- Thời gian: [ngày/giờ]
- Người tham gia: [tên]
- Blameless? **YES** (incident review không đổ lỗi cá nhân)

### 5 Whys:
1. Why did the issue happen?
2. Why wasn't it detected earlier?
3. Why did our monitoring not catch it?
4. Why does our platform allow this?
5. Why do we not have a runbook for this specific case?

### Action Items:
| # | Hành động | Người phụ trách | Deadline |
|---|-----------|----------------|----------|
| 1 | [VD: Thêm Constraint Gatekeeper để block pod privileged] | [Tên] | [Ngày] |
| 2 | [VD: Tạo CloudWatch Alarm phát hiện node spike CPU] | [Tên] | [Ngày] |
| 3 | | | |
| 4 | | | |

### Link tài liệu liên quan:
- CloudWatch log: [link]
- Slack thread: [link]
- Commit fix: [link]
- <details><summary>Logs (click to expand)</summary>
  ...
  </details>
