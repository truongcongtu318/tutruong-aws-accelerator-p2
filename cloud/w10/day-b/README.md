# W10 Day B — Secrets Rotation & Supply Chain Security

## Mục tiêu học tập

Day B của tuần 10 tập trung vào việc quản lý bí mật (Secrets) an toàn trong Kubernetes thông qua tích hợp các nhà cung cấp bên ngoài (External Secrets Operator - ESO), và bảo vệ chuỗi cung ứng phần mềm (Software Supply Chain Security) bằng cách quét lỗ hổng ảnh (Trivy) và ký xác nhận nguồn gốc ảnh (Cosign).

Sau khi hoàn thành Day B, bạn cần nắm vững:

1. **External Secrets Operator (ESO)**: Kiến trúc của ESO, cách cấu hình `SecretStore`/`ClusterSecretStore` kết nối tới AWS Secrets Manager, định nghĩa `ExternalSecret` và thiết lập tần suất đồng bộ (`refreshInterval < 60s`).
2. **Quét ảnh trong CI/CD (Trivy)**: Cách tích hợp Trivy vào GitHub Actions workflow để tự động quét lỗ hổng bảo mật của Docker image và cấu hình chính sách tự động từ chối (fail-on) khi phát hiện lỗi nghiêm trọng (`HIGH`, `CRITICAL`).
3. **Ký xác nhận Docker Image (Cosign)**: Cách sinh cặp khóa Cosign, ký xác nhận Docker image bằng khóa bí mật, và kiểm tra chữ ký ở Admission Controller (ví dụ: Kyverno hoặc Gatekeeper) để chặn các image không rõ nguồn gốc.
4. **Exception Policy**: Cách thiết lập cơ chế ngoại lệ bảo mật cho các lỗ hổng (CVE Exception) hoặc image đặc biệt có thời hạn rõ ràng.

---

## 1. External Secrets Operator (ESO)

Trong Kubernetes, mặc định `Secret` chỉ được mã hoá dưới dạng **Base64** và lưu trong etcd. Điều này không đủ an toàn và gây khó khăn khi quản lý tập trung trên nhiều môi trường.

**External Secrets Operator (ESO)** là một Kubernetes operator đồng bộ hóa các bí mật từ các API quản lý bí mật bên ngoài (như AWS Secrets Manager, HashiCorp Vault, Google Secret Manager) trực tiếp vào Kubernetes Secrets.

### Kiến trúc ESO:
1. **SecretStore / ClusterSecretStore**: Khai báo thông tin kết nối và xác thực tới nhà cung cấp Secrets bên ngoài (ví dụ: dùng AWS IAM Role hoặc static AWS credentials).
   - `SecretStore` có phạm vi trong 1 Namespace.
   - `ClusterSecretStore` có phạm vi trên toàn Cluster.
2. **ExternalSecret**: Định nghĩa cụ thể bí mật nào cần kéo về từ nhà cung cấp bên ngoài, đặt tên cho K8s Secret đích, và thiết lập khoảng thời gian tự động kéo lại (`refreshInterval`).

### 🔄 Cơ chế xoay vòng (Secrets Rotation):
Nếu bạn thay đổi một giá trị secret trên AWS Secrets Manager, ESO sẽ kéo phiên bản mới nhất về sau khoảng thời gian `refreshInterval`.
- Một mục tiêu lớn của W10 là setup **Secrets rotate < 60s no-restart**. Nghĩa là ứng dụng tự động nhận biết secret thay đổi mà không cần restart pod (ví dụ: ứng dụng liên tục đọc file secret mount hoặc có cơ chế reload config).

---

## 2. Quét lỗ hổng ảnh trong CI (Image Scanning với Trivy)

**Trivy** là một công cụ quét bảo mật mạnh mẽ và dễ sử dụng cho container images, git repositories, và Kubernetes configurations.

### 🛡️ Tích hợp Trivy vào Pipeline (CI):
Trong CI/CD pipeline, trước khi push một image lên registry (như ECR, Docker Hub), ta phải chạy Trivy để quét lỗ hổng (CVE).
- Thiết lập chính sách **fail-on-severity**: Nếu phát hiện lỗ hổng mức độ `HIGH` hoặc `CRITICAL`, pipeline sẽ tự động chuyển sang trạng thái thất bại (red) và không cho phép merge hoặc deploy.

---

## 3. Ký xác thực ảnh (Image Signing với Cosign)

Chỉ quét lỗ hổng là chưa đủ, ta cần đảm bảo image đang chạy trên production thực sự được build từ pipeline chính thức của công ty, chứ không phải do hacker upload đè lên.

**Cosign** (thuộc dự án Sigstore) giúp đơn giản hóa việc ký, xác minh và lưu trữ container image.

### Luồng hoạt động:
1. **Tạo Key**: Tạo cặp khóa public/private key bằng Cosign (`cosign generate-key-pair`).
2. **Ký ảnh (Sign)**: Ở bước cuối cùng của CI pipeline (sau khi image đã được build và scan thành công), dùng khóa private key để ký image (`cosign sign`). Chữ ký này sẽ được push trực tiếp lên container registry bên cạnh image.
3. **Xác minh ảnh (Verify)**:
   - Trên cluster, cấu hình một Admission Controller (như Gatekeeper với webhook hoặc Kyverno) để chặn đứng mọi pod mới tạo nếu image của nó chưa được ký bằng khóa public key tương ứng.

---

## 4. Ngoại lệ CVE (Exception Policy)

Trong thực tế, có những lỗ hổng bảo mật (CVE) được Trivy phát hiện nhưng chưa có bản vá (patch) từ nhà phát triển thư viện, hoặc đó là một false-positive không ảnh hưởng đến app. Để tránh block pipeline, ta cần dùng cơ chế ngoại lệ.

- **Trivy Ignore File (`.trivyignore`)**: Ghi danh sách các ID CVE cần bỏ qua, kèm theo lý do và thời gian hết hạn (expiration date) để sau một khoảng thời gian nhóm bảo mật phải kiểm tra lại.
- **Exception ADR (Architecture Decision Record)**: Tài liệu hóa lý do vì sao một lỗ hổng cụ thể được bỏ qua.

---

## Tài liệu đọc thêm (Highly Recommended)
- [External Secrets Operator Docs](https://external-secrets.io/latest/)
- [Trivy GitHub Actions](https://github.com/aquasecurity/trivy-action)
- [Sigstore/Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Kyverno Image Verification](https://kyverno.io/docs/writing-policies/verify-images/)
