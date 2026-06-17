# W10 Day C — Thực hành Platform Integration & Incident Response

Lab này giúp bạn tích hợp toàn stack W8→W10 bằng ResourceQuota/LimitRange, giả lập sự cố (chaos test) để ứng cứu bằng Runbook, và giám sát chi phí AWS.

## 🎯 Mục tiêu bài lab
1. Áp dụng ResourceQuota và LimitRange vào namespace để giới hạn tài nguyên.
2. Kiểm thử giới hạn tài nguyên bằng cách ép K8s quá tải (stress pod).
3. Đóng vai SRE thực hành ứng cứu sự cố bằng Incident Response Runbook.
4. Cấu hình Cost Anomaly Detection trên AWS.

---

## 🚀 Phần 1: Platform Resource Hardening

### Bước 1.1: Apply ResourceQuota & LimitRange

```bash
# Apply manifest cấu hình giới hạn
kubectl apply -f platform-bootstrap/01-limits-quota.yaml

# Kiểm tra trạng thái LimitRange
kubectl describe limitrange demo-limits -n w10-demo

# Kiểm tra trạng thái ResourceQuota
kubectl describe resourcequota demo-quota -n w10-demo
# Bạn sẽ thấy cột "Used" và "Hard" hiển thị tài nguyên đã/được phép dùng.
```

### Bước 1.2: Test LimitRange tự động gán request/limit

Tạo pod không khai báo resources:
```bash
kubectl run default-resources --image=nginx:1.27-alpine -n w10-demo
```
Kiểm tra cấu hình resources được tự động inject:
```bash
kubectl get pod default-resources -n w10-demo -o yaml | grep -A 5 resources
# Bạn phải thấy CPU request: 200m, memory request: 256Mi tự động được chèn vào pod!

# Clean up
kubectl delete pod default-resources -n w10-demo
```

### Bước 1.3: Test ResourceQuota chặn over-provisioning

1. Tạo deployment yêu cầu vượt quá giới hạn (ví dụ: request 3 CPU, trong khi Quota cho phép tối đa 2 CPU):
   ```yaml
   # Tạo file test-quota.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: heavy-deployment
     namespace: w10-demo
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: heavy
     template:
       metadata:
         labels:
           app: heavy
       spec:
         containers:
           - name: app
             image: nginx:1.27-alpine
             resources:
               requests:
                 cpu: "1000m"  # 3 replica * 1000m = 3000m = 3 CPU (vượt 2 CPU quota)
                 memory: "512Mi"
   ```
2. Thử apply:
   ```bash
   kubectl apply -f test-quota.yaml
   ```
3. Xem lỗi trả về hoặc trạng thái ReplicaSet:
   ```bash
   kubectl get rs -n w10-demo
   kubectl describe replicaset heavy-deployment-xxxxx -n w10-demo
   # Bạn sẽ thấy thông báo: pods "heavy-deployment-xxxx" is forbidden: exceeded quota: demo-quota, requested: requests.cpu=1000m, used: requests.cpu=0, limited: requests.cpu=2
   # Trình quản lý ngăn không cho tạo pod mới do quá quota!
   ```

---

## 🚀 Phần 2: Thực hành Incident Response (Simulated Outage)

### Kịch bản giả lập (Chaos Test)
*Ứng dụng web chạy bị rò rỉ bộ nhớ (memory leak) đột ngột làm cạn kiệt RAM và sập service.*

### Bước 2.1: Nhận diện sự cố (Detect)
Tạo pod giả lập memory leak:
```bash
# Chạy pod sử dụng nhiều RAM
kubectl run stress-pod --image=polinux/stress --restart=Never -n w10-demo \
  --overrides='{"spec": {"containers": [{"name": "stress-pod", "image": "polinux/stress", "command": ["stress", "--vm", "1", "--vm-bytes", "1500M", "--timeout", "60s"], "resources": {"limits": {"memory": "1Gi"}}}]}}'
```
Kiểm tra xem pod có bị OOMKilled không:
```bash
kubectl get pods -n w10-demo -w
# Pod sẽ nhanh chóng chuyển sang trạng thái OOMKilled hoặc Error vì vượt quá giới hạn 1Gi RAM!
```

### Bước 2.2: Tiến hành ứng cứu sự cố
1. Copy file `runbooks/ir-runbook-template.md` sang một file thực tế, ví dụ `runbooks/incident-20260617-oom.md`.
2. Điền thông tin sự cố.
3. Thực hiện các bước **Contain** (cách ly pod bị crash, scale down app) và **Recover** (giới hạn memory limit chặt chẽ hơn, cấu hình probe).
4. Viết **Post-mortem** phân tích nguyên nhân và các Action Items.

---

## 🚀 Phần 3: Giám sát chi phí AWS (Cost Guard)

1. Mở **AWS Billing Console** $\rightarrow$ **Cost Anomaly Detection**.
2. Thiết lập một Daily monitor cho toàn bộ AWS Services (chọn **Dimensional** và service).
3. Đăng ký thông báo Email hoặc Slack webhook (ví dụ với mức cảnh báo > $10/ngày).
4. Quan sát cấu hình mẫu trong file `platform-bootstrap/02-cost-guard-example.tf`.

---

## 📝 Kết quả cần đạt cuối Day C
- [ ] Áp dụng thành công LimitRange và ResourceQuota vào namespace w10-demo.
- [ ] Kiểm thử thành công trường hợp bị chặn (exceeded quota) và gán mặc định (default resources).
- [ ] Điền và hoàn thành một file Incident Response runbook thực tế dựa trên template `ir-runbook-template.md`.
- [ ] Hiểu cách setup AWS Cost Anomaly Detection để phòng tránh cost spike.
