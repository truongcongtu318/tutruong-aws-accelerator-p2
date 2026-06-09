# W9 Day A — GitOps & CI/CD

## Mục tiêu học

Day A tương ứng **T2 08/06**. Chủ đề chính là đưa Kubernetes platform từ kiểu thao tác tay sang kiểu **GitOps-managed**.

Sau Day A, bạn cần nắm chắc:

1. **GitOps** là gì và vì sao Git trở thành source of truth.
2. Khác nhau giữa CI, CD truyền thống và GitOps CD.
3. Vai trò của **GitHub Actions** trong pipeline kiểm tra manifest trên Pull Request.
4. Vai trò của **ArgoCD** trong việc đồng bộ trạng thái từ Git vào Kubernetes cluster.
5. Khái niệm **desired state**, **actual state**, **sync**, **drift**, **reconcile**.
6. Cách tổ chức repo GitOps cơ bản cho app và platform.
7. Các pattern quan trọng: **app-of-apps**, **sync waves**, rollback bằng `git revert`.
8. Vì sao sau W9 không nên `kubectl apply` tay nữa.

---

## 1. Bối cảnh từ W8 sang W9

Ở W8, ta đã có Kubernetes cluster local bằng minikube và chạy được các component cơ bản như app, service, ingress hoặc database demo.

Cách triển khai thường gặp ở W8:

```text
Developer viết manifest YAML
        ↓
kubectl apply -f deployment.yaml
        ↓
Cluster thay đổi ngay
```

Cách này học ban đầu thì dễ, nhưng khi đi làm thật sẽ có nhiều vấn đề:

- Không biết ai apply manifest nào.
- Không review được thay đổi trước khi deploy.
- Khó rollback về version cũ.
- Cluster có thể khác Git vì có người sửa tay.
- Dev/staging/prod dễ bị lệch cấu hình.

W9 chuyển sang tư duy:

```text
Git repository = source of truth
        ↓
Pull Request để review thay đổi
        ↓
CI kiểm tra YAML/Kustomize/Helm
        ↓
Merge vào main
        ↓
ArgoCD tự sync vào cluster
```

---

## 2. GitOps là gì?

**GitOps** là phương pháp vận hành hạ tầng/app bằng Git. Tất cả trạng thái mong muốn của hệ thống được mô tả trong Git, và một controller trong cluster liên tục đảm bảo cluster giống Git.

Nói đơn giản:

```text
GitOps = Git + IaC/YAML + Pull Request + Controller tự sync
```

Trong Kubernetes, GitOps thường dùng:

- Git repo chứa manifest.
- Pull Request để thay đổi.
- ArgoCD hoặc Flux để reconcile cluster.
- Metrics/logs để quan sát kết quả deploy.

### Git là source of truth

Source of truth nghĩa là nơi đáng tin nhất để trả lời câu hỏi: hệ thống hiện tại nên chạy như thế nào?

Với GitOps:

- Muốn đổi số replica → sửa YAML trong Git.
- Muốn đổi image tag → sửa YAML trong Git.
- Muốn rollback → revert commit.
- Muốn audit → xem commit history.

Không nên sửa trực tiếp bằng:

```bash
kubectl edit deployment my-app
kubectl set image deployment/my-app app=my-app:v2
kubectl apply -f local-file.yaml
```

Các lệnh này có thể hữu ích khi debug tạm thời, nhưng không nên là workflow chính.

---

## 3. CI/CD và GitOps khác nhau thế nào?

### CI — Continuous Integration

CI trả lời câu hỏi: **code/config mới có hợp lệ không?**

Ví dụ GitHub Actions chạy khi mở PR:

- Check format YAML.
- Validate Kubernetes manifest.
- Chạy test app.
- Build Docker image.
- Scan security cơ bản.
- Sinh preview plan nếu dùng Terraform/Kustomize/Helm.

### CD truyền thống

CD truyền thống thường là pipeline trực tiếp deploy:

```text
GitHub Actions
   ↓
kubectl apply / helm upgrade
   ↓
Cluster
```

Pipeline cần credential mạnh để truy cập cluster. Nếu pipeline lỗi hoặc secret bị lộ thì nguy hiểm.

### GitOps CD

GitOps CD để controller trong cluster chủ động kéo trạng thái từ Git:

```text
Git repo
   ↓ pull/reconcile
ArgoCD trong cluster
   ↓ apply
Kubernetes cluster
```

Ưu điểm:

- Cluster credential nằm trong cluster, không cần đưa quá nhiều quyền cho CI.
- ArgoCD có UI để xem app sync/health.
- Dễ phát hiện drift.
- Dễ rollback bằng Git.
- Audit trail rõ ràng.

---

## 4. ArgoCD là gì?

**ArgoCD** là GitOps controller cho Kubernetes. Nó theo dõi một Git repo, đọc manifest, rồi đồng bộ vào cluster.

Các khái niệm chính:

| Khái niệm | Ý nghĩa |
|---|---|
| Application | Object của ArgoCD đại diện cho một app hoặc một nhóm manifest |
| Source | Git repo/path/branch chứa manifest |
| Destination | Cluster và namespace sẽ deploy vào |
| Sync | Áp dụng desired state từ Git vào cluster |
| Health | Trạng thái app có chạy tốt không |
| OutOfSync | Cluster khác Git |
| Synced | Cluster giống Git |
| Drift | Có thay đổi ngoài Git làm cluster lệch |

### Luồng hoạt động

```text
1. User merge PR vào main
2. Git repo thay đổi manifest
3. ArgoCD phát hiện commit mới
4. ArgoCD so sánh desired state với actual state
5. Nếu khác, app thành OutOfSync
6. ArgoCD sync manifest vào cluster
7. App về Synced/Healthy nếu chạy ổn
```

---

## 5. ArgoCD vs Flux

Cả ArgoCD và Flux đều là GitOps controller phổ biến.

| Tiêu chí | ArgoCD | Flux |
|---|---|---|
| UI | Có UI mạnh, dễ học | Chủ yếu CLI/Git-native |
| Trải nghiệm beginner | Dễ nhìn trạng thái app | Cần quen controller/resource hơn |
| CNCF | Graduated | Graduated |
| Multi-tenancy | Mạnh | Mạnh |
| Phù hợp W9 | Rất phù hợp để demo/quan sát | Tốt nhưng ít trực quan hơn |

Trong W9, ta ưu tiên **ArgoCD** vì UI trực quan và dễ show-and-tell.

---

## 6. GitHub Actions plan-on-PR

Với GitOps, PR phải được kiểm tra trước khi merge. Đây là phần **plan-on-PR**.

Ví dụ workflow kiểm tra Kubernetes YAML:

```yaml
name: gitops-check

on:
  pull_request:
    paths:
      - "cloud/w9/**"
      - ".github/workflows/gitops-check.yml"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install kubeconform
        run: |
          curl -L -o kubeconform.tar.gz https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz
          tar -xzf kubeconform.tar.gz
          sudo mv kubeconform /usr/local/bin/kubeconform

      - name: Validate Kubernetes manifests
        run: |
          kubeconform -strict -summary cloud/w9/day-a/argocd
```

Ý tưởng quan trọng:

```text
PR mở ra
  → CI validate manifest
  → reviewer xem diff
  → pass thì merge
  → ArgoCD mới sync
```

---

## 7. Apply-on-merge trong GitOps

Trong CD truyền thống, apply-on-merge thường nghĩa là GitHub Actions chạy `kubectl apply` sau khi merge.

Trong GitOps, apply-on-merge nên hiểu là:

```text
Merge vào branch chính
  → Git state thay đổi
  → ArgoCD tự apply/sync
```

Tức là GitHub Actions không nhất thiết phải cầm kubeconfig để deploy. Nó chỉ cần validate, build image, update tag hoặc tạo PR.

---

## 8. Cấu trúc repo GitOps đề xuất

Trong W9, thư mục Day A có thể tổ chức như sau:

```text
cloud/w9/day-a/
  README.md
  .github-workflow-example.md
  argocd/
    applications/
      demo-app.yaml
    projects/
      default-project.yaml
  manifests/
    demo-app/
      namespace.yaml
      deployment.yaml
      service.yaml
      kustomization.yaml
```

Trong repo thật, GitHub Actions nằm ở `.github/workflows/`, nhưng để học có thể để file ví dụ trong Day A trước rồi copy ra root khi cần.

---

## 9. Ví dụ Kubernetes manifest được GitOps quản lý

### Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: demo-app
          image: nginx:1.25
          ports:
            - containerPort: 80
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: demo
spec:
  selector:
    app: demo-app
  ports:
    - port: 80
      targetPort: 80
```

---

## 10. Ví dụ ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: cloud/w9/day-a/manifests/demo-app
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Giải thích:

- `repoURL`: repo chứa manifest.
- `targetRevision`: branch/tag/commit ArgoCD theo dõi.
- `path`: thư mục manifest.
- `destination`: cluster và namespace đích.
- `automated.prune`: xoá resource ngoài Git nếu bị remove khỏi repo.
- `automated.selfHeal`: nếu ai sửa tay trong cluster, ArgoCD tự đưa về đúng Git.
- `CreateNamespace=true`: tự tạo namespace nếu chưa có.

---

## 11. App-of-apps pattern

Khi có nhiều app, không muốn apply từng ArgoCD Application thủ công. Pattern **app-of-apps** tạo một root Application quản lý nhiều child Application.

```text
root-app
  ├── frontend-app
  ├── backend-app
  ├── database-app
  └── monitoring-app
```

Root app trỏ vào thư mục chứa các Application YAML:

```text
cloud/w9/day-a/argocd/applications/
  frontend.yaml
  backend.yaml
  monitoring.yaml
```

Lợi ích:

- Chỉ bootstrap một lần root app.
- App mới chỉ cần thêm YAML vào Git.
- Dễ quản lý platform nhiều component.

---

## 12. Sync waves

**Sync waves** giúp kiểm soát thứ tự apply resource.

Ví dụ:

```text
Wave 0: Namespace, CRD
Wave 1: ConfigMap, Secret
Wave 2: Deployment, Service
Wave 3: Ingress, Rollout, AnalysisTemplate
```

Trong ArgoCD, dùng annotation:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

Khi nào cần sync waves?

- CRD phải có trước custom resource.
- Namespace phải có trước workload.
- Secret/ConfigMap nên có trước Deployment.
- Monitoring stack nên có trước canary analysis.

---

## 13. Rollback trong GitOps

Có 2 kiểu rollback hay gặp:

### Rollback bằng Git revert

Đây là cách đúng với GitOps.

```bash
git revert <bad-commit>
git push
```

Sau đó ArgoCD sync commit revert vào cluster.

Ưu điểm:

- Lưu lịch sử rõ ràng.
- Cluster quay về đúng trạng thái trong Git.
- Có audit trail.

### Rollback bằng kubectl rollout undo

```bash
kubectl rollout undo deployment/demo-app -n demo
```

Cách này có thể dùng trong tình huống khẩn cấp, nhưng có vấn đề:

- Cluster thay đổi ngoài Git.
- ArgoCD có thể sync lại theo Git và ghi đè rollback.
- Lịch sử Git không phản ánh sự cố.

Kết luận: GitOps ưu tiên `git revert`. `kubectl rollout undo` chỉ nên là emergency action có ghi chú và sau đó phải cập nhật Git.

---

## 14. Checklist Day A

### GitOps concepts

- [ ] Hiểu GitOps là gì.
- [ ] Hiểu Git là source of truth.
- [ ] Phân biệt desired state và actual state.
- [ ] Hiểu drift là gì.
- [ ] Hiểu reconcile loop là gì.

### CI/CD

- [ ] Phân biệt CI và CD.
- [ ] Biết plan-on-PR dùng để kiểm tra gì.
- [ ] Biết apply-on-merge trong GitOps là ArgoCD sync sau merge.
- [ ] Biết vì sao CI không nên giữ quá nhiều quyền truy cập cluster.

### ArgoCD

- [ ] Biết ArgoCD Application là gì.
- [ ] Đọc hiểu `source`, `destination`, `syncPolicy`.
- [ ] Biết trạng thái `Synced`, `OutOfSync`, `Healthy`, `Degraded`.
- [ ] Biết `prune` và `selfHeal`.

### Patterns

- [ ] Hiểu app-of-apps.
- [ ] Hiểu sync waves.
- [ ] Biết rollback bằng `git revert`.
- [ ] Biết hạn chế của `kubectl rollout undo` trong GitOps.

---

## 15. Kết quả mong muốn cuối Day A

Cuối Day A, bạn cần có thể tự giải thích:

1. Vì sao GitOps tốt hơn `kubectl apply` tay.
2. ArgoCD đang theo dõi repo/path nào.
3. Khi sửa image tag trong Git thì cluster thay đổi như thế nào.
4. Khi cluster bị sửa tay, ArgoCD phát hiện drift ra sao.
5. Nếu deploy lỗi, rollback bằng commit revert thế nào.

Deliverable tối thiểu:

```text
cloud/w9/day-a/
  README.md
  argocd/applications/demo-app.yaml
  manifests/demo-app/namespace.yaml
  manifests/demo-app/deployment.yaml
  manifests/demo-app/service.yaml
  manifests/demo-app/kustomization.yaml
```
