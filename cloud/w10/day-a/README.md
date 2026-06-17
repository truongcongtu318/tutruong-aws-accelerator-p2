# W10 Day A — RBAC & Admission Policy (OPA/Gatekeeper)

## Mục tiêu học tập

Day A của tuần 10 tập trung vào việc bảo mật Kubernetes ở mức độ phân quyền tài nguyên (RBAC) và kiểm soát tài nguyên được triển khai lên cluster (Admission Controllers / Policy Enforcement).

Sau khi hoàn thành Day A, bạn cần nắm vững:

1. **Kubernetes RBAC**: Cách thức phân quyền chi tiết thông qua các object `Role`, `ClusterRole`, `RoleBinding`, `ClusterRoleBinding` và quản lý thực thể định danh `ServiceAccount`.
2. **Kubernetes Admission Control**: Hiểu về chu kỳ vòng đời của một API Request (Mutating vs Validating Admission Controller).
3. **OPA/Gatekeeper**: Kiến trúc của Gatekeeper trên Kubernetes, cách viết chính sách bằng ngôn ngữ **Rego**, và cách phân tách giữa `ConstraintTemplate` (luật chung) và `Constraint` (áp dụng cụ thể).
4. **ValidatingAdmissionPolicy**: Cách định nghĩa chính sách bảo mật gốc (native validation) tích hợp từ K8s 1.30+ không cần cài thêm Controller bên thứ ba.
5. **Cách test quyền**: Sử dụng lệnh thực tế `kubectl auth can-i` để đóng vai làm người dùng/service account khác nhằm kiểm tra phân quyền.

---

## 1. Kubernetes Role-Based Access Control (RBAC)

RBAC là cơ chế kiểm soát truy cập dựa trên vai trò của người dùng trong hệ thống Kubernetes. Quy trình phân quyền bao gồm 3 thành phần chính:

1. **Subjects (Đối tượng)**: Ai muốn thực hiện hành động?
   - **User**: Người dùng thực tế (được quản lý bởi certificate, OIDC, v.v., K8s không lưu trữ User object).
   - **Group**: Nhóm người dùng.
   - **ServiceAccount**: Tài khoản định danh cho ứng dụng/pod chạy bên trong cluster.
2. **API Groups + Resources + Verbs (Hành động và Tài nguyên)**: Được làm gì trên cái gì?
   - **Resources**: `pods`, `services`, `deployments`, `secrets`, v.v.
   - **Verbs**: `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`.
3. **Role & RoleBinding (Phân quyền)**: Gắn kết Subject với Quyền.
   - **Namespace Scope**: `Role` & `RoleBinding` (chỉ có tác dụng trong 1 namespace).
   - **Cluster Scope**: `ClusterRole` & `ClusterRoleBinding` (có tác dụng trên toàn cluster, áp dụng cho cả các tài nguyên cluster-level như `Node`, `PersistentVolume`, `Namespace` hoặc cho tất cả namespaces).

### 💡 Lưu ý quan trọng:
- RBAC trong Kubernetes tuân theo nguyên lý **Least Privilege** (Quyền tối thiểu) và **Chỉ cho phép thêm (additive only)** — không có luật loại trừ (deny rule). Nếu không được cấp quyền một cách tường minh, hành động đó mặc định sẽ bị cấm.
- Bạn có thể bind một `ClusterRole` cho một Subject bằng `RoleBinding` để cấp quyền định nghĩa trong ClusterRole đó nhưng giới hạn duy nhất trong phạm vi namespace của `RoleBinding` đó (rất hữu ích để tái sử dụng các role mẫu như `view`, `edit`, `admin`).

---

## 2. API Request Lifecycle & Admission Controllers

Khi bạn thực hiện lệnh `kubectl apply -f manifest.yaml`, request của bạn sẽ đi qua các bước sau trên `kube-apiserver`:

```text
Request → [ Authentication & Authorization ] → [ Mutating Admission ] → [ Schema Validation ] → [ Validating Admission ] → [ ETCD Store ]
```

1. **Authentication & Authorization**: Kiểm tra danh tính (Token, Cert) và kiểm tra xem Subject có quyền làm hành động đó không (RBAC).
2. **Mutating Admission Webhooks**: Chỉnh sửa request (ví dụ: tự động inject Sidecar container, tự động gán storage class mặc định, v.v.).
3. **Schema Validation**: Kiểm tra xem cú pháp YAML có đúng cấu trúc Kubernetes API không.
4. **Validating Admission Webhooks**: Kiểm tra tính hợp lệ của request dựa trên các chính sách doanh nghiệp (ví dụ: cấm dùng image tag `latest`, cấm chạy pod ở quyền root, v.v.). Nếu bước này từ chối (reject), request sẽ thất bại ngay lập tức và etcd không lưu trữ gì cả.

---

## 3. OPA/Gatekeeper là gì?

**Open Policy Agent (OPA)** là một engine thực thi chính sách đa năng. **Gatekeeper** là một project mã nguồn mở giúp tích hợp OPA trực tiếp vào Kubernetes dưới dạng một **Validating Admission Webhook**.

### Kiến trúc Gatekeeper:
Gatekeeper hoạt động dựa trên cơ chế CRD (Custom Resource Definition) với 2 thành phần chính:

1. **ConstraintTemplate**:
   - Định nghĩa logic kiểm tra (chính sách) bằng ngôn ngữ **Rego**.
   - Khai báo các tham số (parameters) đầu vào mà chính sách này chấp nhận.
   
2. **Constraint**:
   - Áp dụng `ConstraintTemplate` vào các đối tượng cụ thể (ví dụ: chỉ áp dụng cho Namespace có label `production` hoặc áp dụng cho toàn bộ Deployments).
   - Truyền giá trị cụ thể cho các tham số đã khai báo trong template.

### Ví dụ về cơ chế chặn:
```yaml
# ConstraintTemplate định nghĩa logic Rego để cấm một số label nhất định
# Constraint chỉ định: Cấm label "test" trên Namespace "production"
```

---

## 4. ValidatingAdmissionPolicy (Native K8s 1.30+)

Kể từ Kubernetes 1.30 (đạt trạng thái Stable), Kubernetes giới thiệu một cơ chế kiểm tra chính sách gốc **không cần webhook** và không cần cài thêm agent bên ngoài (như Gatekeeper hay Kyverno). Nó sử dụng ngôn ngữ **CEL (Common Expression Language)**.

CEL rất nhẹ, thực thi cực nhanh ngay trong quá trình xử lý của `kube-apiserver`.

### Cấu trúc cơ bản:
1. **ValidatingAdmissionPolicy**: Khai báo logic kiểm tra bằng CEL (ví dụ: `object.spec.replicas <= 5`).
2. **ValidatingAdmissionPolicyBinding**: Liên kết chính sách đó với các resource hoặc namespace chỉ định.

---

## 5. Các câu lệnh gối đầu giường để debug quyền (RBAC)

1. Kiểm tra xem user hiện tại có quyền thực hiện hành động nào đó không:
   ```bash
   kubectl auth can-i create deployments
   kubectl auth can-i delete pods --all-namespaces
   ```

2. Kiểm tra xem một **ServiceAccount** cụ thể có quyền thực hiện hành động đó không:
   ```bash
   kubectl auth can-i list secrets --as=system:serviceaccount:default:my-serviceaccount
   ```

3. Kiểm tra xem một **User** hoặc **Group** bất kỳ có quyền không:
   ```bash
   kubectl auth can-i get configmaps --as=developer-user
   kubectl auth can-i create services --as-group=dev-group
   ```

---

## Tài liệu đọc thêm (Highly Recommended)
- [Kubernetes RBAC Official Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/website/docs/howto/)
- [CEL in Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)
