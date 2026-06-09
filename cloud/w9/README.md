# W9 — Deliver Smartly: GitOps + Observability + Canary

## Tổng quan tuần

W9 nâng cấp platform từ W8 Kubernetes cơ bản lên một quy trình delivery thông minh hơn:

```text
W8: Kubernetes chạy được app
        ↓
W9: GitOps-managed + Observability + Canary auto-abort
```

Mục tiêu cuối tuần:

- Không deploy bằng `kubectl apply` tay nữa.
- Mọi thay đổi đi qua Git và Pull Request.
- ArgoCD tự đồng bộ manifest từ Git vào cluster.
- Observability stack đo được metrics/logs/traces.
- Có SLO/SLI và burn rate alert.
- Deploy canary bằng Argo Rollouts và tự abort khi metric xấu.

---

## Lịch học tương ứng

| Ngày | Folder | Nội dung |
|---|---|---|
| T2 08/06 | `day-a/` | GitOps & CI/CD — GitHub Actions, ArgoCD, app-of-apps, sync waves, rollback |
| T3 09/06 | `day-b/` | Observability — OTel, Prometheus, Grafana, Loki, SLO/SLI, burn rate alert |
| T4 10/06 | `day-c/` | Progressive Delivery — Argo Rollouts, Rollout CRD, AnalysisTemplate, auto-abort |
| T5-T6 | `lab/` | GitOps-ify W8 platform + bolt-on observability + canary |

---

## Cấu trúc thư mục

```text
cloud/w9/
  README.md
  day-a/      # GitOps & CI/CD
    README.md
  day-b/      # Observability — SLO/SLI/OTel
    README.md
  day-c/      # Progressive Delivery — Canary
    README.md
  lab/        # GitOps-ify + bolt-on
  reflection.md
```

---

## Cách học đề xuất

1. Đọc `day-a/README.md` trước để hiểu GitOps workflow.
2. Đọc `day-b/README.md` để hiểu vì sao deploy cần metrics/logs/traces.
3. Đọc `day-c/README.md` để hiểu canary auto-abort dựa trên metrics.
4. Làm lab T5-T6 bằng cách ghép 3 phần lại:

```text
GitHub PR
  → CI validate manifest
  → merge
  → ArgoCD sync
  → Argo Rollouts canary
  → Prometheus/Grafana đo metric
  → metric xấu thì auto-abort
```
