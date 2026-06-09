# W8 Day A — Thực hành GitOps với ArgoCD & GitHub Actions

Lab này giúp bạn thực hành triển khai GitOps trên minikube local.

## 🎯 Mục tiêu bài lab
1. Cài đặt ArgoCD lên local Kubernetes cluster (minikube).
2. Tạo một ứng dụng demo và quản lý manifest qua Git.
3. Cấu hình ArgoCD Application để tự động đồng bộ (sync) và phát hiện lệch cấu hình (drift).
4. Thiết lập GitHub Actions Workflow cơ bản để kiểm tra cú pháp manifest (linting) trên Pull Request.

---

## 🛠️ Chuẩn bị môi trường
- Đã cài và chạy **minikube** (hoặc cluster K8s local khác).
- Đã cài **kubectl** kết nối tới cluster.
- Repo Git của bạn đã được push lên GitHub.

---

## 🚀 Các bước thực hiện

### Bước 1: Cài đặt ArgoCD
Chạy lệnh tạo namespace và apply manifest cài đặt chính thức của ArgoCD:

```bash
# Tạo namespace riêng cho ArgoCD
kubectl create namespace argocd

# Cài đặt ArgoCD non-HA (phù hợp chạy thử local)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Chờ các pod của ArgoCD chuyển sang trạng thái `Running`:
```bash
kubectl get pods -n argocd -w
```

### Bước 2: Truy cập ArgoCD UI
Để truy cập giao diện web của ArgoCD trên localhost:

1. Chạy **port-forward**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
2. Mở trình duyệt truy cập: `https://localhost:8080` (bỏ qua cảnh báo SSL/HTTPS).
3. Tài khoản đăng nhập:
   - **Username**: `admin`
   - **Password**: Lấy mật khẩu khởi tạo bằng lệnh sau (giải mã base64):
     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
     ```

---

### Bước 3: Tạo code cấu hình cho Demo App
Tạo các file manifest cho ứng dụng demo của bạn trong folder này.

#### 1. Tạo file `manifests/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gitops-demo
```

#### 2. Tạo file `manifests/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web
  namespace: gitops-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
```

#### 3. Tạo file `manifests/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-web
  namespace: gitops-demo
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: demo-web
```

Commit các file trên và push lên GitHub repo của bạn.

---

### Bước 4: Tạo ArgoCD Application
Bây giờ, chúng ta sẽ bảo ArgoCD theo dõi repo của bạn và deploy ứng dụng. Bạn có thể làm qua UI hoặc tạo manifest khai báo sau:

Tạo file `argocd-app.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: local-gitops-demo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<your-username>/<your-repo-name>.git' # Đổi thành repo của bạn
    targetRevision: main
    path: cloud/w9/day-a/manifests
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: gitops-demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply file này lên cluster:
```bash
kubectl apply -f argocd-app.yaml
```

Mở giao diện ArgoCD UI để kiểm tra ứng dụng `local-gitops-demo` đã được sync thành công (`Synced` và `Healthy`).

---

### Bước 5: Thử nghiệm cơ chế Drift Detection & Self-Healing
1. Sửa trực tiếp số lượng replica của deployment trên cluster bằng lệnh:
   ```bash
   kubectl scale deployment demo-web --replicas=5 -n gitops-demo
   ```
2. Quan sát trên ArgoCD UI:
   - Bạn sẽ thấy ArgoCD phát hiện trạng thái cluster bị lệch (**OutOfSync**).
   - Vì cấu hình có `selfHeal: true`, ArgoCD sẽ tự động kích hoạt tiến trình đồng bộ ngược lại, scale pod về đúng số lượng 2 như khai báo trong Git.

---

### Bước 6: Setup GitHub Actions (Plan-on-PR)
Tạo file `.github/workflows/gitops-lint.yml` ở thư mục root của dự án để tự động check lỗi cú pháp manifest khi có Pull Request:

```yaml
name: GitOps Manifest Lint

on:
  pull_request:
    paths:
      - 'cloud/w9/day-a/manifests/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run Kubeconform
        uses: yannh/kubeconform@v0.6.3
        with:
          args: "-summary -strict cloud/w9/day-a/manifests"
```

Thử tạo một branch mới, sửa sai cú pháp trong file deployment (ví dụ: gõ sai thụt lề thụt dòng), mở Pull Request và kiểm tra xem Github Actions có báo đỏ (fail) không.

---

## 📝 Kết quả cần đạt
- [ ] ArgoCD chạy thành công trên minikube local.
- [ ] Có thể đăng nhập vào UI của ArgoCD.
- [ ] Deploy ứng dụng demo tự động qua Git.
- [ ] Tự tay test thành công tính năng tự phục hồi (Self-Healing) khi chỉnh sửa trực tiếp trên cluster.
- [ ] Github Actions chạy thành công khi tạo Pull Request sửa đổi manifest.
