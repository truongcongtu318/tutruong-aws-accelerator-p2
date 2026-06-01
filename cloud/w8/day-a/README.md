# W8 Day A — Terraform Foundation

## Mục tiêu học

Day A tập trung vào 2 phần chính:

1. Hiểu **Infrastructure as Code (IaC)** là gì và vì sao cần dùng.
2. Làm quen với **Terraform HCL syntax**: provider, resource, variable, output, locals, data source, expression.

---

## 1. Infrastructure as Code là gì?

**Infrastructure as Code (IaC)** là cách quản lý hạ tầng bằng code thay vì thao tác thủ công trên giao diện cloud console.

Ví dụ thay vì click tạo EC2, VPC, S3 bucket trên AWS Console, ta viết file Terraform mô tả hạ tầng mong muốn, sau đó dùng Terraform để tạo/sửa/xoá.

### Lợi ích của IaC

- **Version control**: hạ tầng được quản lý bằng Git.
- **Repeatable**: tạo lại môi trường giống nhau nhiều lần.
- **Automation**: giảm thao tác tay, giảm lỗi con người.
- **Reviewable**: thay đổi hạ tầng có thể review qua Pull Request.
- **Documented by code**: code chính là tài liệu sống của hệ thống.

### Declarative vs Imperative

| Kiểu | Ý nghĩa | Ví dụ |
|---|---|---|
| Declarative | Mô tả trạng thái mong muốn | Terraform |
| Imperative | Mô tả từng bước thực hiện | Bash script |

Terraform là declarative: ta khai báo muốn có resource gì, Terraform tự tính cách tạo/sửa/xoá để đạt trạng thái đó.

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
- Và nhiều provider khác

---

## 3. Terraform workflow cơ bản

Các lệnh quan trọng:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

Ý nghĩa:

| Lệnh | Mục đích |
|---|---|
| `terraform init` | Khởi tạo working directory, tải provider |
| `terraform fmt` | Format code Terraform |
| `terraform validate` | Kiểm tra syntax/config |
| `terraform plan` | Xem Terraform sẽ thay đổi gì |
| `terraform apply` | Thực thi thay đổi |
| `terraform destroy` | Xoá resource đã tạo |

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
  type    = string
  default = "demo-app"
}
```

Dùng variable:

```hcl
name = var.app_name
```

### Output

Output in ra thông tin sau khi apply.

```hcl
output "file_path" {
  value = local_file.hello.filename
}
```

### Locals

Locals dùng để đặt giá trị trung gian/tái sử dụng.

```hcl
locals {
  full_name = "${var.app_name}-${var.environment}"
}
```

### Data source

Data source dùng để đọc dữ liệu có sẵn từ provider, không trực tiếp tạo resource.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
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
| `map(string)` | `{ env = "dev" }` |
| `object` | `{ name = string, port = number }` |

---

## 6. Checklist Day A

- [ ] Hiểu IaC là gì
- [ ] Phân biệt declarative và imperative
- [ ] Biết Terraform dùng để làm gì
- [ ] Biết provider là gì
- [ ] Biết resource là gì
- [ ] Biết variable là gì
- [ ] Biết output là gì
- [ ] Biết locals là gì
- [ ] Biết format block HCL
- [ ] Chạy được bài exercise Terraform local
- [ ] Commit bài với message `[W8-D1] terraform basics`
