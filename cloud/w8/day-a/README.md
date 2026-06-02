# W8 Day A — Terraform Foundation

## Mục tiêu học

Day A tập trung vào nền tảng Terraform để chuẩn bị cho các phần sau: state, module, AWS infrastructure, Kubernetes/GitOps.

Sau Day A, bạn cần nắm chắc:

1. **IaC — Infrastructure as Code** là gì.
2. **Terraform** dùng để làm gì.
3. **HCL syntax** cơ bản.
4. Các khái niệm lõi: `provider`, `resource`, `variable`, `output`, `locals`, `data source`, `state`.
5. Workflow: `init → fmt → validate → plan → apply → destroy`.
6. State management cơ bản.
7. Module và best practices cơ bản.
8. Cấu trúc một project Terraform chuẩn.

---

## 1. Infrastructure as Code là gì?

**Infrastructure as Code (IaC)** là cách quản lý hạ tầng bằng code thay vì thao tác thủ công trên giao diện cloud console.

Ví dụ thay vì click tạo EC2, VPC, S3 bucket trên AWS Console, ta viết file Terraform mô tả hạ tầng mong muốn, sau đó dùng Terraform để tạo/sửa/xoá.

```text
Manual cloud console
  → click tay
  → khó lặp lại
  → khó review
  → dễ sai giữa dev/staging/prod

Infrastructure as Code
  → viết code
  → commit lên Git
  → review được
  → chạy tự động
  → tái tạo được môi trường
```

### Lợi ích của IaC

- **Version control**: hạ tầng được quản lý bằng Git.
- **Repeatable**: tạo lại môi trường giống nhau nhiều lần.
- **Automation**: giảm thao tác tay, giảm lỗi con người.
- **Reviewable**: thay đổi hạ tầng có thể review qua Pull Request.
- **Documented by code**: code chính là tài liệu sống của hệ thống.
- **Consistency**: dev/staging/prod có thể dùng cùng logic.
- **Auditability**: biết ai thay đổi gì, khi nào.

### Declarative vs Imperative

| Kiểu | Ý nghĩa | Ví dụ |
|---|---|---|
| Declarative | Mô tả trạng thái mong muốn | Terraform, Kubernetes YAML |
| Imperative | Mô tả từng bước thực hiện | Bash script, manual commands |

Terraform là **declarative**: ta khai báo muốn có resource gì, Terraform tự tính cách tạo/sửa/xoá để đạt trạng thái đó.

---

## 2. Terraform là gì?

Terraform là công cụ IaC của HashiCorp, dùng ngôn ngữ **HCL — HashiCorp Configuration Language**.

Terraform có thể quản lý nhiều nền tảng:

- AWS
- Azure
- Google Cloud
- Kubernetes
- GitHub
- Docker
- Cloudflare
- Datadog
- Và nhiều provider khác

Terraform hoạt động bằng cách:

```text
Terraform code (.tf)
        ↓
terraform init
        ↓
terraform plan
        ↓
terraform apply
        ↓
Real infrastructure on AWS/K8s/etc
        ↓
terraform.tfstate records mapping
```

---

## 3. Terraform workflow cơ bản

Các lệnh quan trọng:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
```

Ý nghĩa:

| Lệnh | Mục đích |
|---|---|
| `terraform init` | Khởi tạo working directory, tải provider/module, cấu hình backend |
| `terraform fmt` | Format code Terraform |
| `terraform validate` | Kiểm tra syntax/config nội bộ |
| `terraform plan` | Xem Terraform sẽ thay đổi gì |
| `terraform apply` | Thực thi thay đổi |
| `terraform output` | Xem output sau apply |
| `terraform destroy` | Xoá resource đã tạo |

Plan output cần nhớ:

| Ký hiệu | Ý nghĩa |
|---|---|
| `+` | Create resource mới |
| `~` | Update resource hiện có |
| `-` | Destroy resource |
| `-/+` | Replace: xoá cũ rồi tạo mới |
| `+/-` | Replace: tạo mới trước rồi xoá cũ |

---

## 4. HCL syntax cơ bản

### Block

Cấu trúc phổ biến:

```hcl
block_type "label_1" "label_2" {
  argument = value
}
```

Ví dụ:

```hcl
resource "local_file" "hello" {
  filename = "hello.txt"
  content  = "Hello Terraform"
}
```

### Argument

Argument là cặp key/value trong block:

```hcl
filename = "hello.txt"
content  = "Hello Terraform"
```

### Provider

Provider là plugin giúp Terraform nói chuyện với platform/API.

```hcl
provider "aws" {
  region = "ap-southeast-1"
}
```

### Resource

Resource là object Terraform quản lý.

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = "my-demo-bucket"
}
```

### Variable

Variable giúp truyền input vào Terraform.

```hcl
variable "app_name" {
  description = "Application name."
  type        = string
  default     = "demo-app"
}
```

Dùng variable:

```hcl
name = var.app_name
```

### Output

Output in ra thông tin sau khi apply.

```hcl
output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.demo.bucket
}
```

### Locals

Locals dùng để đặt giá trị trung gian/tái sử dụng.

```hcl
locals {
  name_prefix = "${var.app_name}-${var.environment}"

  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### Data source

Data source dùng để đọc dữ liệu có sẵn từ provider, không trực tiếp tạo resource.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

---

## 5. Type system cần biết

| Type | Ví dụ |
|---|---|
| `string` | `"dev"` |
| `number` | `3` |
| `bool` | `true` |
| `list(string)` | `["a", "b"]` |
| `set(string)` | `toset(["a", "b"])` |
| `map(string)` | `{ env = "dev" }` |
| `object` | `{ name = string, port = number }` |
| `list(object(...))` | list nhiều object cùng schema |

Ví dụ variable có validation:

```hcl
variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

---

## 6. File Terraform thường gặp

Terraform không bắt buộc tên file, nhưng best practice là tách rõ trách nhiệm:

```text
terraform.tf      # Terraform version, providers, backend
providers.tf      # provider config
variables.tf      # input variables
locals.tf         # local values: naming, tags
main.tf           # resources/modules chính
outputs.tf        # output values
data.tf           # data sources
```

Với project lớn hơn có thể tách:

```text
network.tf        # VPC, subnet, route table
compute.tf        # EC2, ECS, EKS worker nodes
security.tf       # SG, IAM, policies
storage.tf        # S3, EBS, EFS
```

---

## 7. Các tài liệu trong Day A

| File | Nội dung |
|---|---|
| `README.md` | Tổng quan Day A và checklist học |
| `concepts.md` | Giải thích chi tiết các khái niệm Terraform |
| `workflow-state-modules.md` | Workflow, state management, modules |
| `best-practices.md` | Best practices Terraform |
| `project-structure.md` | Cấu trúc project Terraform chuẩn |
| `exercise-1-hello-terraform.md` | Exercise local provider không cần AWS |
| `learn-terraform-get-started-aws/` | Lab nhỏ theo HashiCorp Get Started AWS |

---

## 8. Checklist Day A đầy đủ

### IaC & Terraform

- [ ] Hiểu IaC là gì
- [ ] Phân biệt declarative và imperative
- [ ] Biết Terraform dùng để làm gì
- [ ] Biết Terraform khác CloudFormation/Pulumi/Ansible ở mức cơ bản

### HCL syntax

- [ ] Biết block syntax
- [ ] Biết argument là gì
- [ ] Biết expression là gì
- [ ] Biết string interpolation
- [ ] Biết conditional expression
- [ ] Biết list/map/object types

### Terraform core concepts

- [ ] Biết provider là gì
- [ ] Biết resource là gì
- [ ] Biết data source là gì
- [ ] Biết variable là gì
- [ ] Biết local là gì
- [ ] Biết output là gì
- [ ] Biết dependency graph cơ bản

### Workflow

- [ ] Biết `terraform init`
- [ ] Biết `terraform fmt`
- [ ] Biết `terraform validate`
- [ ] Biết `terraform plan`
- [ ] Biết `terraform apply`
- [ ] Biết `terraform destroy`
- [ ] Đọc được plan output: `+`, `~`, `-`, `-/+`

### State & module

- [ ] Hiểu `terraform.tfstate` dùng để làm gì
- [ ] Biết vì sao không commit state lên Git
- [ ] Biết local state vs remote state
- [ ] Hiểu module là gì
- [ ] Biết root module vs child module
- [ ] Biết gọi module registry hoặc local

### Best practices

- [ ] Không commit secret
- [ ] Không commit `.terraform/`
- [ ] Không commit `terraform.tfstate`
- [ ] Dùng `terraform.tfvars.example` thay vì commit `terraform.tfvars`
- [ ] Tách file rõ trách nhiệm
- [ ] Dùng naming convention và common tags
- [ ] Chạy `terraform fmt` trước commit
- [ ] Review kỹ `terraform plan` trước `apply`

---

## 9. Kết quả mong muốn cuối Day A

Sau Day A, bạn chưa cần production-ready, nhưng cần đọc hiểu được một Terraform project nhỏ:

```text
terraform.tf
providers.tf
variables.tf
main.tf
outputs.tf
```

Và tự giải thích được:

1. Provider nào đang dùng?
2. Resource nào sẽ được tạo?
3. Input variable là gì?
4. Output là gì?
5. State sẽ lưu gì?
6. Nếu apply thì Terraform sẽ thay đổi gì?
7. File nào không được commit?
