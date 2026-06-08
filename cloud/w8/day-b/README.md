# W8 Day B — Kubernetes Container/Orchestration

## Mục tiêu học

Day B tập trung vào 2 phần chính:

1. Hiểu **Docker/Container** nền tảng: image, container, Dockerfile, build, run.
2. Hiểu **Kubernetes cơ bản**: Pod, Deployment, Service, ConfigMap, Secret, Probes, NetworkPolicy.

Cuối ngày bạn phải:

- Hiểu container là gì và vì sao cần
- Biết build image và run container bằng Docker
- Hiểu Kubernetes dùng để làm gì
- Biết các object cơ bản: Pod, Deployment, Service
- Biết cách config app bằng ConfigMap/Secret
- Biết health check bằng Probes
- Cài sẵn Docker Desktop + minikube + kubectl

---

## Kiến thức nền trước khi học

Trước khi học K8s, bạn cần hiểu Docker/Container trước vì:

```text
Docker         → tạo và chạy 1 container
Kubernetes     → quản lý hàng trăm/ngàn container
```

Nếu không hiểu container là gì, học K8s sẽ rất mơ hồ.

Thứ tự học trong ngày:

```text
1. Docker/Container cơ bản        → concepts-docker.md
2. Thực hành Docker                → exercise-1-docker-basics.md
3. Kubernetes concepts             → concepts-kubernetes.md
4. Thực hành kubectl + minikube    → exercise-2-kubectl-minikube.md
```

---

## Tài liệu tham khảo

### Docker

- Docker Docs — https://docs.docker.com
- Docker Curriculum — https://docker-curriculum.com
- Series mentor Nghĩa — https://kkloudtarus.net/en/blog/series/docker-from-basics-to-swarm

### Kubernetes

- Kubernetes Docs — https://kubernetes.io/docs
- Kubernetes Basics (interactive) — https://kubernetes.io/docs/tutorials/kubernetes-basics
- minikube — https://minikube.sigs.k8s.io/docs/start
- kubectl Cheat Sheet — https://kubernetes.io/docs/reference/kubectl/cheatsheet

---

## Tools cần cài

Kiểm tra trước khi bắt đầu:

```bash
docker --version
kubectl version --client
minikube version
```

Nếu chưa cài:

- Docker Desktop — https://docs.docker.com/get-docker
- kubectl — https://kubernetes.io/docs/tasks/tools/
- minikube — https://minikube.sigs.k8s.io/docs/start

---

## Cấu trúc thư mục Day B

```text
cloud/w8/day-b/
  README.md                          # file này
  concepts-docker.md                 # lý thuyết Docker/Container
  concepts-kubernetes.md             # lý thuyết Kubernetes
  exercise-1-docker-basics.md        # thực hành Docker
  exercise-2-kubectl-minikube.md     # thực hành K8s trên minikube
  sample-app/                        # app mẫu để containerize (tạo khi thực hành)
  k8s-manifests/                     # yaml K8s (tạo khi thực hành)
```

---

## Checklist Day B

### Docker

- [ ] Hiểu container khác VM thế nào
- [ ] Hiểu image là gì
- [ ] Viết được Dockerfile đơn giản
- [ ] Build được image
- [ ] Run được container
- [ ] Biết port mapping
- [ ] Biết volume mount cơ bản
- [ ] Biết `docker ps`, `docker logs`, `docker exec`

### Kubernetes

- [ ] Hiểu K8s dùng để làm gì
- [ ] Hiểu kiến trúc: cluster, node, control plane
- [ ] Hiểu Pod là gì
- [ ] Hiểu Deployment là gì
- [ ] Hiểu Service là gì (ClusterIP, NodePort, LoadBalancer)
- [ ] Hiểu ConfigMap dùng để làm gì
- [ ] Hiểu Secret dùng để làm gì
- [ ] Hiểu Readiness Probe và Liveness Probe
- [ ] Hiểu NetworkPolicy cơ bản
- [ ] Khởi động được minikube
- [ ] Deploy được app đơn giản lên minikube
- [ ] Dùng được `kubectl get`, `kubectl describe`, `kubectl logs`
