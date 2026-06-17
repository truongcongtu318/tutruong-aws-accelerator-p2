# W10 Day B — Thực hành Secrets Rotation & Supply Chain Security

Lab này giúp bạn thực hành cấu hình đồng bộ bí mật tự động từ AWS Secrets Manager sử dụng External Secrets Operator (ESO), và bảo mật chuỗi cung ứng container bằng Trivy + Cosign.

## 🎯 Mục tiêu bài lab
1. Cài đặt External Secrets Operator (ESO) lên cluster.
2. Cấu hình ESO đồng bộ bí mật từ AWS Secrets Manager định kỳ `< 60s`.
3. Kiểm thử cơ chế cập nhật tự động không cần khởi động lại container (no-restart).
4. Sinh cặp khóa Cosign và mô phỏng quá trình ký image trên GitHub Actions.
5. Cài đặt Kyverno và thiết lập chính sách chặn ảnh không có chữ ký.
6. Thiết lập Trivy quét mã nguồn & ảnh trong pipeline với chính sách từ chối CVE nghiêm trọng.

---

## 🛠️ Chuẩn bị môi trường
- Cluster minikube/K8s đang chạy.
- Đã cài Helm (để cài đặt ESO và Kyverno).
- AWS CLI đã cấu hình (hoặc IAM Role được gán nếu chạy trên EKS).

---

## 🚀 Phần 1: Quản lý Secrets với External Secrets Operator (ESO)

### Bước 1.1: Cài đặt ESO qua Helm

```bash
# Add Helm repo của ESO
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Cài đặt ESO
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true

# Chờ ESO ready
kubectl get pods -n external-secrets
```

### Bước 1.2: Tạo Secret trên AWS Secrets Manager

Chạy lệnh AWS CLI để tạo một secret demo:
```bash
aws secretsmanager create-secret --name "/w10-demo/db/credentials" \
  --secret-string '{"username":"db_admin","password":"SuperSecurePassword123","host":"db-prod.internal","port":"5432"}' \
  --region ap-southeast-1
```

### Bước 1.3: Cấu hình SecretStore & ExternalSecret

*Lưu ý: Để `SecretStore` kết nối được với AWS Secrets Manager từ Local K8s (minikube), bạn cần cấp quyền cho nó. Một cách đơn giản khi thực hành local là tạo K8s secret chứa credentials của AWS và map vào SecretStore (trong production, bạn MUST dùng IRSA).*

Tạo K8s secret chứa AWS Creds tạm thời để test:
```bash
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=$AWS_ACCESS_KEY_ID \
  --from-literal=secret-access-key=$AWS_SECRET_ACCESS_KEY \
  -n w10-demo
```

Sửa lại phần xác thực trong `eso/01-eso-manifests.yaml` thành dùng credentials secret trên nếu chạy ở local, sau đó apply:
```bash
# Áp dụng ServiceAccount, SecretStore, ExternalSecret và Deployment test
kubectl apply -f eso/
```

### Bước 1.4: Kiểm tra đồng bộ Secrets

```bash
# Kiểm tra trạng thái ExternalSecret
kubectl get externalsecret -n w10-demo
# Trạng thái phải là: SecretSynced

# Xem K8s Secret được ESO tạo ra tự động
kubectl get secret db-credentials -n w10-demo -o yaml
# Kiểm tra các data key: DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT đã được giải mã đúng
```

### Bước 1.5: Test xoay vòng Secrets (Rotation) không cần Restart

1. Cập nhật mật khẩu trên AWS Secrets Manager:
   ```bash
   aws secretsmanager put-secret-value --secret-id "/w10-demo/db/credentials" \
     --secret-string '{"username":"db_admin","password":"NewChangedPassword999","host":"db-prod.internal","port":"5432"}' \
     --region ap-southeast-1
   ```
2. Theo dõi K8s Secret trên Cluster:
   ```bash
   # Đợi tối đa 45 giây (refreshInterval của ta)
   kubectl get secret db-credentials -n w10-demo -o jsonpath="{.data.DB_PASSWORD}" | base64 -d
   # Mật khẩu mới "NewChangedPassword999" phải xuất hiện mà không cần tác động gì!
   ```
3. Xem Deployment `app-with-eso` tự reload (Stakater Reloader):
   - Nếu bạn đã cài đặt Reloader Operator trên cluster, nó sẽ phát hiện `db-credentials` secret thay đổi và tự động thực hiện rolling-update pod.
   - Nếu ứng dụng của bạn mount file secret, file `/etc/db/DB_PASSWORD` sẽ tự động cập nhật bên trong container (K8s tự sync volume mount định kỳ) mà không cần restart container!

---

## 🚀 Phần 2: Supply Chain Security với Trivy & Cosign

### Bước 2.1: Quét lỗ hổng cục bộ bằng Trivy

Cài đặt Trivy trên máy cục bộ (hoặc container):
```bash
# MacOS/Linux
brew install aquasecurity/trivy/trivy

# Quét một image cũ có nhiều lỗ hổng
trivy image nginx:1.19

# Quét và fail nếu phát hiện lỗ hổng HIGH/CRITICAL
trivy image --severity HIGH,CRITICAL --exit-code 1 nginx:1.19
# → Trả về exit code 1 (báo đỏ trong CI)
```

### Bước 2.2: Ký Image bằng Cosign

1. Cài đặt Cosign:
   ```bash
   # MacOS
   brew install cosign
   ```
2. Sinh cặp khóa:
   ```bash
   cosign generate-key-pair
   # Nhập mật khẩu bảo vệ khóa bí mật (passphrase)
   # Sinh ra 2 file: cosign.key và cosign.pub
   ```
3. Ký một image của riêng bạn (ví dụ đẩy lên registry cá nhân):
   ```bash
   cosign sign --key cosign.key <registry-path>/<image-name>:<tag>
   # Nhập passphrase để ký. Chữ ký sẽ được đẩy lên registry.
   ```

### Bước 2.3: Bắt buộc xác thực chữ ký (Image Verification) trên Cluster

1. Cài đặt Kyverno qua Helm:
   ```bash
   helm repo add kyverno https://kyverno.github.io/kyverno/
   helm repo update
   helm install kyverno kyverno/kyverno -n kyverno --create-namespace
   ```
2. Cập nhật public key của bạn vào file `signing/02-kyverno-verify-image.yaml` tại mục `publicKeys: |-`.
3. Apply ClusterPolicy của Kyverno:
   ```bash
   kubectl apply -f signing/02-kyverno-verify-image.yaml
   ```
4. Kiểm thử:
   - Thử deploy một pod có image chưa ký $\rightarrow$ Sẽ bị Kyverno chặn lại và báo lỗi.
   - Deploy pod có image đã ký bằng cặp khóa tương ứng $\rightarrow$ Pod được deploy thành công.

---

## 📝 Kết quả cần đạt cuối Day B
- [ ] ESO cài đặt thành công, đồng bộ được secret từ AWS sang K8s Secret.
- [ ] Thay đổi trên AWS tự động cập nhật xuống K8s trong `< 60s`.
- [ ] Tích hợp được Trivy vào GitHub Actions workflow (đã tạo file `.github/workflows/w10-secure-build.yml` hoặc map vào `.github/workflows/`).
- [ ] Có file `.trivyignore` để xử lý các exception lỗ hổng bảo mật.
- [ ] Hiểu quy trình ký image bằng Cosign và bắt buộc chữ ký trên K8s thông qua Policy Engine.
