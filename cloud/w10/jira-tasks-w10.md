# Jira Tasks — W10: Secure & Operate

Dưới đây là danh sách các task Jira cho tuần W10, chia theo chủ đề.
Mỗi task gồm: **Summary** (tiêu đề), **Description** (học được gì, khái niệm chính, câu lệnh đã dùng), **Acceptance Criteria** (tiêu chí hoàn thành).

---

## Task 1: RBAC — Role-Based Access Control

**Summary:** [W10] RBAC — Phân quyền Kubernetes với Role/ClusterRole/ServiceAccount

**Description:**
h3. Học được những gì?

* **Kiến trúc RBAC:** Hiểu cách Kubernetes kiểm soát truy cập dựa trên 3 thành phần: Subject (User/Group/ServiceAccount), Resource (pods/services/deployments...), Verb (get/list/create/delete...).
* **Role vs ClusterRole:**
  - `Role`: namespace-scoped (chỉ có hiệu lực trong 1 namespace).
  - `ClusterRole`: cluster-scoped (nodes, PVs, namespaces) hoặc dùng với RoleBinding để cấp quyền trong namespace cụ thể.
* **RoleBinding vs ClusterRoleBinding:**
  - `RoleBinding`: gán quyền trong 1 namespace.
  - `ClusterRoleBinding`: gán quyền toàn cluster.
* **3 role mẫu thực tế:**
  - `viewer`: chỉ xem pods/services/deployments (get/list/watch).
  - `developer`: CRUD apps trong namespace (pods, deployments, services, configmaps, secrets).
  - `sre`: full quyền namespace + xem node/PV/clusterrole + quản lý RBAC trong namespace.
* **ServiceAccount:** Tài khoản định danh cho pod, dùng để gán quyền.
* **Cách test quyền:**
  - `kubectl auth can-i get pods --as=system:serviceaccount:<ns>:<sa>` — kiểm tra quyền của SA.
  - `kubectl auth can-i create deployments` — kiểm tra quyền của user hiện tại.

h3. Các file đã tạo:
- day-a/rbac/00-namespace-sa.yaml
- day-a/rbac/01-clusterroles.yaml
- day-a/rbac/02-rolebindings.yaml
- day-a/rbac/03-demo-deployment.yaml

**Acceptance Criteria:**
- [ ] Phân biệt được Role và ClusterRole.
- [ ] Phân biệt được RoleBinding và ClusterRoleBinding.
- [ ] Tạo được 3 ServiceAccount gán 3 role khác nhau.
- [ ] Sử dụng được kubectl auth can-i để xác minh quyền.

---

## Task 2: Admission Policy — OPA/Gatekeeper & ValidatingAdmissionPolicy

**Summary:** [W10] Admission Policy — OPA Gatekeeper (Rego) & ValidatingAdmissionPolicy (CEL)

**Description:**
h3. Học được những gì?

* **Admission Controller lifecycle:** Request → Authn/Authz → Mutating Admission → Schema Validation → Validating Admission → etcd.
* **OPA/Gatekeeper:**
  - Gatekeeper là Validating Admission Webhook tích hợp OPA vào K8s.
  - **ConstraintTemplate:** định nghĩa logic chính sách bằng ngôn ngữ Rego (tái sử dụng).
  - **Constraint:** áp dụng template vào resource cụ thể (Namespace, Pod...) với tham số cụ thể.
  - Rego cơ bản: `violation[{"msg": msg}] { ... }`, `input.review.object`, `input.parameters`.
* **2 chính sách đã tạo:**
  1. `K8sRequiredLabels` — yêu cầu namespace có label `team` và `environment` với regex kiểm tra giá trị.
  2. `K8sContainerLimits` — cấm privileged container, bắt buộc `runAsNonRoot=true`.
* **ValidatingAdmissionPolicy (K8s 1.30+ native):**
  - Dùng CEL (Common Expression Language) — nhẹ, chạy trong kube-apiserver, không cần webhook.
  - `expression: "object.spec.replicas <= 10"` — giới hạn replicas cho namespace production.

h3. Các file đã tạo:
- day-a/policies/constrainttemplate-requiredlabels.yaml
- day-a/policies/constrainttemplate-hardening.yaml
- day-a/policies/constraint-requiredlabels-ns.yaml
- day-a/policies/constraint-hardening.yaml
- day-a/policies/validatingadmissionpolicy-replicas.yaml

**Acceptance Criteria:**
- [ ] Hiểu được sự khác biệt giữa ConstraintTemplate và Constraint.
- [ ] Đọc được cú pháp Rego cơ bản.
- [ ] Cài đặt được Gatekeeper và apply constraint thành công.
- [ ] Viết được ValidatingAdmissionPolicy bằng CEL.

---

## Task 3: External Secrets Operator (ESO) & Secrets Rotation

**Summary:** [W10] Secrets Rotation — External Secrets Operator (ESO) + AWS Secrets Manager

**Description:**
h3. Học được những gì?

* **Vấn đề:** Secret của K8s chỉ là base64, lưu trong etcd, khó quản lý tập trung.
* **ESO (External Secrets Operator):**
  - **SecretStore / ClusterSecretStore:** kết nối tới AWS Secrets Manager (dùng IRSA hoặc static creds).
  - **ExternalSecret:** định nghĩa secret cần kéo về, map field từ AWS vào K8s Secret.
  - **refreshInterval:** tần suất ESO kiểm tra và đồng bộ thay đổi từ AWS (< 60s).
* **Cơ chế rotation no-restart:**
  - ESO cập nhật K8s Secret.
  - Volume mount của K8s tự refresh file trong pod (không restart cần).
  - Hoặc dùng Reloader (stakater) để tự động rolling-update khi secret thay đổi.
* **IRSA (IAM Roles for Service Accounts):** cách an toàn nhất để cấp quyền AWS cho pod — không cần access key trong cluster.

h3. Các file đã tạo:
- day-b/eso/01-eso-manifests.yaml
- day-b/eso/02-eso-serviceaccount.yaml

**Acceptance Criteria:**
- [ ] Cài đặt và cấu hình được ESO trên cluster.
- [ ] ESO đồng bộ thành công secret từ AWS Secrets Manager.
- [ ] Thay đổi secret trên AWS tự động cập nhật xuống K8s trong < 60s.
- [ ] Hiểu được luồng rotation không restart.

---

## Task 4: Supply Chain Security — Trivy & Cosign

**Summary:** [W10] Supply Chain Security — Trivy Image Scanning + Cosign Signing

**Description:**
h3. Học được những gì?

* **Trivy — Image Scanning:**
  - Quét CVE trên Docker image.
  - Tích hợp vào GitHub Actions với `aquasecurity/trivy-action`.
  - Chính sách `exit-code: 1` + `severity: HIGH,CRITICAL` → tự động fail CI khi có lỗ hổng nghiêm trọng.
  - `.trivyignore`: exception list cho CVE, có expiration date.
* **Cosign — Image Signing:**
  - Sinh cặp key: `cosign generate-key-pair` → `cosign.key` (private) + `cosign.pub` (public).
  - Ký image: `cosign sign --key cosign.key <image>`.
  - Xác minh: `cosign verify --key cosign.pub <image>`.
* **Kyverno ClusterPolicy:** chặn pod nếu image chưa được ký bằng public key tương ứng.
  - `validationFailureAction: Enforce` — chặn cứng.
  - `verifyImages.attestors[].entries[].keys.publicKeys` — public key để verify.
* **SLSA Levels:**
  - Level 1: CI build + scan (đã làm).
  - Level 2: Signed image (đã làm với Cosign).
  - Level 3: Provenance (đang hướng tới).

h3. Các file đã tạo:
- day-b/ci-trivy/.trivyignore
- day-b/ci-trivy/w10-secure-build.yml
- day-b/signing/01-cosign-public-key.yaml
- day-b/signing/02-kyverno-verify-image.yaml
- day-b/signing/03-slsa-readme.md

**Acceptance Criteria:**
- [ ] Tích hợp được Trivy vào CI pipeline, fail khi có HIGH/CRITICAL.
- [ ] Sinh được cặp key Cosign và ký image.
- [ ] Cài đặt Kyverno và chặn được image chưa ký.
- [ ] Hiểu SLSA supply chain levels.

---

## Task 5: Platform Integration — ResourceQuota & LimitRange

**Summary:** [W10] Platform Integration — ResourceQuota & LimitRange

**Description:**
h3. Học được những gì?

* **ResourceQuota:** giới hạn tổng tài nguyên của 1 namespace.
  - `hard.pods`: số pod tối đa trong namespace.
  - `hard.requests.cpu/memory`: tổng CPU/memory requests tối đa.
  - `hard.limits.cpu/memory`: tổng CPU/memory limits tối đa.
  - Nếu vượt quota, K8s từ chối tạo pod mới.
* **LimitRange:** giới hạn container riêng lẻ trong namespace.
  - `default`: gán limit mặc định nếu developer không khai báo resources.
  - `max/min`: trần và sàn cho CPU/memory.
  - Nếu không khai báo resources, LimitRange tự inject default.
* **Ý nghĩa platform:** Đảm bảo không team nào chiếm hết tài nguyên cluster, ổn định cho multi-tenant.
* **Chaos test:** dùng `polinux/stress` image để simulate memory leak và kiểm tra OOMKill + tự phục hồi.

h3. Các file đã tạo:
- day-c/platform-bootstrap/01-limits-quota.yaml

**Acceptance Criteria:**
- [ ] Apply và kiểm tra được ResourceQuota (thử vượt quota).
- [ ] Apply và kiểm tra được LimitRange tự inject default resources.
- [ ] Hiểu tác dụng của từng field trong ResourceQuota và LimitRange.

---

## Task 6: Incident Response Runbook

**Summary:** [W10] Incident Response — Runbook Template (IR Playbook 6 bước)

**Description:**
h3. Học được những gì?

* **IR Playbook 6 bước (chuẩn AWS):**
  1. **Detect:** Nhận alert từ CloudWatch/Grafana/Slack.
  2. **Triage:** Phân loại P1/P2/P3, xác định phạm vi ảnh hưởng.
  3. **Contain:** Khoanh vùng — taint node, cô lập namespace, network policy.
  4. **Eradicate:** Tìm nguyên nhân gốc — audit log, update image, xoay secret, rút quyền.
  5. **Recover:** Rollback, xoá taint, kiểm tra health.
  6. **Post-mortem:** 5 Whys, action items, blameless culture.
* **K8s commands cho IR:**
  - `kubectl taint nodes <node> compromised=true:NoExecute`
  - `kubectl label namespace <ns> security=isolated`
  - `kubectl rollout undo deployment/<name>`
* **Mẫu runbook thực tế:** đã tạo template đầy đủ, có thể điền ngay khi có sự cố.
* **Kịch bản lab:** simulate memory leak (stress pod) → áp dụng runbook.

h3. Các file đã tạo:
- day-c/runbooks/ir-runbook-template.md

**Acceptance Criteria:**
- [ ] Hiểu 6 bước của Incident Response Playbook.
- [ ] Điền được 1 runbook thực tế khi simulate sự cố.
- [ ] Biết các lệnh K8s cơ bản để contain và recover.

---

## Task 7: Cost Guard — AWS Cost Anomaly Detection

**Summary:** [W10] Cost Guard — AWS Cost Anomaly Detection & Cost Monitoring

**Description:**
h3. Học được những gì?

* **AWS Cost Anomaly Detection:**
  - Dịch vụ tự động phát hiện tăng đột biến chi phí AWS.
  - Monitor types: theo service, theo tag, theo account.
  - Alert: Email, SNS, Slack.
  - Threshold: cảnh báo khi cost spike vượt X% so với baseline.
* **Terraform mẫu:**
  - `aws_ce_anomaly_monitor`: định nghĩa monitor.
  - `aws_ce_anomaly_subscription`: gửi cảnh báo.
* **Kết hợp với K8s:** ResourceQuota gián tiếp kiểm soát cost vì giới hạn tài nguyên → giới hạn chi phí EC2/EKS.

h3. Các file đã tạo:
- day-c/platform-bootstrap/02-cost-guard-example.tf

**Acceptance Criteria:**
- [ ] Hiểu cách AWS Cost Anomaly Detection hoạt động.
- [ ] Cấu hình được monitor và alert cơ bản.
- [ ] Hiểu mối liên hệ giữa ResourceQuota K8s và cost control.

---

## Task 8: Live Session Recap — AWS Security + K8s Hardening với mentor Minh

**Summary:** [W10] Live Session — AWS Security End-to-End & K8s Hardening

**Description:**
h3. Học được những gì?

* **Recap AWS Security Foundation (Phase 1):**
  - Shared Responsibility Model.
  - IAM users/roles/policies, VPC/SG/NACL/WAF, KMS encryption.
  - CloudTrail/CloudWatch/Config, GuardDuty/Security Hub.
  - AWS Organizations/SCP/Control Tower.
* **Container & K8s Security (mới):**
  - ECR image scan.
  - IRSA (IAM Roles for Service Accounts).
  - Pod Security Standards (restricted/baseline).
  - runAsNonRoot + readOnlyRootFilesystem, NetworkPolicy.
  - EKS audit log → CloudWatch.
* **DevSecOps & CI/CD Security (mới):**
  - Trivy CI scan policy (fail-on HIGH/CRITICAL).
  - Cosign/Sigstore keyless OIDC.
  - Admission verify signature.
  - Exception ADR có thời hạn.
  - SLSA supply chain levels.
* **Incident Response on AWS (mới hoàn toàn):**
  - IR playbook 6-step.
  - EC2 isolation pattern (SG swap + EBS snapshot).
  - EventBridge → Lambda auto-isolate.
  - "Khi cluster K8s bị compromise: làm gì 5 phút đầu?"

h3. Câu hỏi đã chuẩn bị:
- IRSA vs static AWS credentials trong pod?
- Verify signature ở CI vs registry vs admission?
- Pod compromised → cách ly pod, node hay namespace?

**Acceptance Criteria:**
- [ ] Tham dự live session.
- [ ] Có ghi chép về 3 mảng mới: Container Security, DevSecOps, IR.

---

## Task 9: Online Test 1 & 2 — Ôn tập và kiểm tra

**Summary:** [W10] Kiểm tra Online Test 1 (D1 + D2 + Live) & Online Test 2 (D3 + Lab)

**Description:**
h3. Online Test 1 — Scope: D1 (RBAC + OPA) + D2 (Secrets + Supply Chain) + Live Session

Thời gian: 60 phút (T4 17:00-18:00)

Nội dung ôn tập:
- [ ] RBAC: Role/ClusterRole/RoleBinding/ClusterRoleBinding, ServiceAccount.
- [ ] Admission Policy: Gatekeeper, ConstraintTemplate vs Constraint, Rego cơ bản.
- [ ] ValidatingAdmissionPolicy: CEL expression.
- [ ] ESO: SecretStore, ExternalSecret, refreshInterval, rotation.
- [ ] Trivy: CI scan, fail-on severity, .trivyignore.
- [ ] Cosign: key generation, signing, verification.
- [ ] Kyverno: verify image signature.
- [ ] AWS Security: IAM, VPC, KMS, GuardDuty, IRSA.
- [ ] DevSecOps: CI/CD security, supply chain.

h3. Online Test 2 — Scope: D3 (Platform Integration + Runbook + Cost Guard) + Lab

Thời gian: 60 phút (T6 15:00-16:00)

Nội dung ôn tập:
- [ ] ResourceQuota & LimitRange.
- [ ] Incident Response Runbook: 6 bước, commands.
- [ ] Cost Guard: AWS Cost Anomaly Detection.
- [ ] Lab: 6-risk cluster cleanup + enforcement.

**Acceptance Criteria:**
- [ ] Hoàn thành Online Test 1.
- [ ] Hoàn thành Online Test 2.

---

## Task 10: Lab Onsite — 6-risk Cluster Cleanup & Enforcement

**Summary:** [W10] Lab — 6-risk Cluster Cleanup & Cluster-level Enforcement

**Description:**
h3. Học được những gì?

Lab full day (T5-T6) với mentor Kiệt + Vương tại Đà Nẵng.

**6 risk cần cleanup:**
1. Privileged containers đang chạy.
2. Secrets lưu trong Git (plaintext).
3. ServiceAccount không dùng đến.
4. Image tag `latest` trong deployment.
5. Namespace không có label chuẩn.
6. RBAC over-privileged (quyền quá lớn).

**Enforcement đã chuẩn bị:**
- [x] 3 ClusterRole rõ ràng (developer/sre/viewer).
- [x] 4 Gatekeeper Constraint enforce (label + privileged/no-root).
- [x] ValidatingAdmissionPolicy (replicas ≤ 10).
- [x] ResourceQuota + LimitRange cho namespace.
- [x] ESO refresh < 60s.
- [x] Kyverno verify image signature.

**Show-and-tell:** Pod 5 người, demo mini platform GitOps + Observability + Canary + Security deploy fresh < 2h.

**Acceptance Criteria:**
- [ ] Cleanup thành công 6 risk trên cluster.
- [ ] 4 Gatekeeper constraint hoạt động và chặn được vi phạm.
- [ ] ESO rotate secret < 60s không restart.
- [ ] Admission reject unsigned image.
- [ ] Demo mini platform end-to-end.
