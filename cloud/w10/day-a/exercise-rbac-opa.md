# W10 Day A — Thực hành RBAC & Admission Policy (OPA/Gatekeeper)

Lab này giúp bạn thực hành phân quyền RBAC và áp dụng chính sách bảo mật bằng OPA/Gatekeeper trên local Kubernetes cluster (minikube).

## 🎯 Mục tiêu bài lab
1. Tạo và kiểm thử các role RBAC cơ bản trên cluster (viewer, developer, sre).
2. Kiểm tra quyền bằng lệnh `kubectl auth can-i` với tư cách service account khác.
3. Cài đặt Gatekeeper lên cluster.
4. Áp dụng 2 ConstraintTemplate và 2 Constraint để chặn vi phạm bảo mật.
5. Sử dụng ValidatingAdmissionPolicy gốc của K8s 1.30+ để giới hạn replicas.

---

## 🛠️ Chuẩn bị môi trường
- Đã cài và chạy **minikube** với Kubernetes version ≥ 1.30 (để có thể dùng ValidatingAdmissionPolicy).
- Đã cài **kubectl** kết nối tới cluster.
- Clone repo và chuyển đến thư mục `cloud/w10/day-a/`.

---

## 🚀 Phần 1: RBAC — Tạo & Kiểm thử ServiceAccount và Role

### Bước 1.1: Apply toàn bộ RBAC manifests

```bash
# Tạo Namespace, ServiceAccount, ClusterRole, RoleBinding
kubectl apply -f rbac/
```

### Bước 1.2: Kiểm tra trạng thái các tài nguyên

```bash
# Xem các ServiceAccount vừa tạo
kubectl get sa -n w10-demo

# Xem các ClusterRole đã tạo
kubectl get clusterrole developer viewer sre

# Xem các RoleBinding
kubectl get rolebinding -n w10-demo
```

### Bước 1.3: Kiểm tra phân quyền từng ServiceAccount

```bash
# 1. Viewer: chỉ có quyền GET/LIST/WATCH
kubectl auth can-i get pods --as=system:serviceaccount:w10-demo:viewer-sa
# → YES

kubectl auth can-i create deployments --as=system:serviceaccount:w10-demo:viewer-sa
# → NO

# 2. Developer: có quyền CRUD cơ bản trong namespace
kubectl auth can-i create deployments --as=system:serviceaccount:w10-demo:developer-sa
# → YES

kubectl auth can-i delete secrets --as=system:serviceaccount:w10-demo:developer-sa
# → YES

kubectl auth can-i list nodes --as=system:serviceaccount:w10-demo:developer-sa
# → NO (developer không có quyền xem cluster-level resource)

# 3. SRE: có quyền CRUD + manage RBAC trong namespace
kubectl auth can-i create rolebindings --as=system:serviceaccount:w10-demo:sre-sa
# → YES

kubectl auth can-i delete rolebindings --as=system:serviceaccount:w10-demo:sre-sa
# → YES

kubectl auth can-i delete nodes --as=system:serviceaccount:w10-demo:sre-sa
# → NO (SRE có thể xem node nhưng không xoá)
```

### Bước 1.4: Deploy demo ứng dụng với developer role

```bash
# Apply deployment demo (đã được gán serviceAccount: developer-sa)
kubectl apply -f rbac/03-demo-deployment.yaml

# Kiểm tra pod chạy với service account đã gán
kubectl get pods -n w10-demo -o yaml | grep serviceAccount
```

---

## 🚀 Phần 2: Gatekeeper — Cài đặt & Áp dụng Constraint

### Bước 2.1: Cài đặt Gatekeeper lên cluster

```bash
# Cài đặt Gatekeeper từ release chính thức
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.18.0/deploy/gatekeeper.yaml

# Chờ Gatekeeper pods Ready
kubectl get pods -n gatekeeper-system -w
```

### Bước 2.2: Tạo ConstraintTemplate và Constraint

```bash
# 1. Tạo ConstraintTemplate "K8sRequiredLabels" và "K8sContainerLimits"
kubectl apply -f policies/constrainttemplate-requiredlabels.yaml
kubectl apply -f policies/constrainttemplate-hardening.yaml

# Kiểm tra template đã được tạo
kubectl get constrainttemplates

# 2. Tạo Constraint cụ thể
kubectl apply -f policies/constraint-requiredlabels-ns.yaml
kubectl apply -f policies/constraint-hardening.yaml

# Kiểm tra constraint đã được tạo và audit
kubectl get k8srequiredlabels
kubectl get k8scontainerlimits
```

### Bước 2.3: Test chính sách labels — Tạo namespace vi phạm

```bash
# Tạo namespace KHÔNG có label team/environment — sẽ bị REJECT
kubectl create namespace bad-ns
# → Error: admission webhook "validation.gatekeeper.sh" denied the request: ...

# Tạo namespace CÓ label đúng
kubectl create namespace good-ns --labels='team=platform,environment=development'
# → OK

# Dọn dẹp
kubectl delete namespace bad-ns good-ns
```

### Bước 2.4: Test chính sách hardening — Deploy pod priviledged

```bash
# Tạo pod chạy privileged mode — sẽ bị REJECT
kubectl run bad-pod --image=nginx:1.27-alpine --restart=Never -n w10-demo \
  --overrides='{"spec": {"containers": [{"name": "bad-pod", "image": "nginx:1.27-alpine", "securityContext": {"privileged": true}}]}}'
# → Error: admission webhook "validation.gatekeeper.sh" denied the request: ...

# Tạo pod không chạy privileged — cũng bị REJECT (vì không set runAsNonRoot=true)
kubectl run good-pod --image=nginx:1.27-alpine --restart=Never -n w10-demo
# → Error: run_as_root_not_set ...

# Tạo pod đúng chuẩn — OK
kubectl run proper-pod --image=nginx:1.27-alpine --restart=Never -n w10-demo \
  --overrides='{"spec": {"containers": [{"name": "proper-pod", "image": "nginx:1.27-alpine", "securityContext": {"runAsNonRoot": true}}]}}'
# → pod/proper-pod created

# Kiểm tra pod chạy ổn
kubectl get pods -n w10-demo

# Xoá pod
kubectl delete pod proper-pod -n w10-demo
```

---

## 🚀 Phần 3: ValidatingAdmissionPolicy (Native K8s 1.30+)

### Bước 3.1: Tạo ValidatingAdmissionPolicy và Binding

```bash
kubectl apply -f policies/validatingadmissionpolicy-replicas.yaml

# Kiểm tra
kubectl get validatingadmissionpolicies
kubectl get validatingadmissionpolicybindings
```

### Bước 3.2: Kiểm tra chính sách — Deploy Deployment quá số replicas

Đánh dấu namespace `w10-demo` với label environment=production để binding match:
```bash
kubectl label namespace w10-demo environment=production
```

```bash
# Deploy với 15 replicas — bị REJECT
kubectl create -n w10-demo deployment overloaded --image=nginx:1.27-alpine --replicas=15
# → Error: ...

# Deploy với 5 replicas — OK
kubectl create -n w10-demo deployment normal --image=nginx:1.27-alpine --replicas=5
# → OK

# Dọn dẹp
kubectl delete deployment normal -n w10-demo
```

---

## 📝 Kết quả cần đạt cuối Day A

### RBAC
- [ ] Hiểu RBAC là gì và cách Role/ClusterRole/ServiceAccount hoạt động.
- [ ] Phân biệt được RoleBinding và ClusterRoleBinding.
- [ ] Sử dụng `kubectl auth can-i` để kiểm tra quyền.
- [ ] Deploy được ứng dụng với ServiceAccount được chỉ định.

### Gatekeeper / OPA
- [ ] Hiểu ngôn ngữ Rego cơ bản và cách viết ConstraintTemplate.
- [ ] Phân biệt ConstraintTemplate (luật chung) và Constraint (áp dụng cụ thể).
- [ ] Cài đặt được Gatekeeper và áp dụng thành công các Constraint.
- [ ] Test được trường hợp bị chặn (denied) và trường hợp thành công.

### ValidatingAdmissionPolicy (Native)
- [ ] Biết viết policy bằng CEL.
- [ ] Hiểu cách Binding map policy với resource/namespace selector.

---

## 💡 Lưu ý nếu gặp vấn đề

1. **Gatekeeper không cài được:**
   - Kiểm tra phiên bản K8s và tải release version phù hợp: `kubectl version`
   - Có thể cần cài Gatekeeper version cũ nếu K8s còn < 1.25.

2. **ValidatingAdmissionPolicy không hoạt động:**
   - Kiểm tra feature gate: `kubectl get --raw /version`
   - K8s < 1.30 không hỗ trợ nativValidatingAdmissionPolicy (cần nâng cấp cluster).

3. **YAML linter báo lỗi multi-document:**
   - Đó là cảnh báo, không phải lỗi thực tế. Kubernetes accept multi-document bằng `---`.

4. **Quên xoá resource test:**
   - Dùng `kubectl delete -f rbac/` để clean up toàn bộ.
   - Gatekeeper constraint vẫn còn audit cho dù resource bị xoá — dùng `kubectl get constraint -o yaml` để xem audit result.
