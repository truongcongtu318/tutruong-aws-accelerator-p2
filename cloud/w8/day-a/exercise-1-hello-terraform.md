# Exercise 1 — Hello Terraform (Local Provider)

## Mục tiêu

Làm quen với Terraform workflow cơ bản mà KHÔNG cần AWS account.
Dùng `local` provider để tạo file trên máy.

---

## Bước 1: Tạo file providers.tf

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
```

**Giải thích:**
- `required_version`: yêu cầu Terraform CLI version >= 1.0
- `required_providers`: khai báo provider cần dùng
- `source`: tên provider trên Terraform Registry
- `version`: version constraint, `~> 2.0` nghĩa là >= 2.0 và < 3.0

---

## Bước 2: Tạo file variables.tf

```hcl
variable "filename" {
  description = "Tên file sẽ tạo"
  type        = string
  default     = "hello.txt"
}

variable "content" {
  description = "Nội dung file"
  type        = string
  default     = "Hello from Terraform!"
}

variable "environment" {
  description = "Môi trường deploy"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment phải là dev, staging, hoặc prod."
  }
}
```

**Giải thích:**
- `description`: mô tả variable
- `type`: kiểu dữ liệu (string, number, bool, list, map...)
- `default`: giá trị mặc định nếu không truyền
- `validation`: kiểm tra giá trị input hợp lệ

---

## Bước 3: Tạo file main.tf

```hcl
locals {
  full_filename = "${var.environment}-${var.filename}"
  timestamp     = timestamp()
}

resource "local_file" "hello" {
  filename = "${path.module}/output/${local.full_filename}"
  content  = <<-EOT
    Environment : ${var.environment}
    Message     : ${var.content}
    Created at  : ${local.timestamp}
  EOT
}

resource "local_file" "summary" {
  filename = "${path.module}/output/summary.txt"
  content  = "File '${local.full_filename}' created in ${var.environment} environment."
}
```

**Giải thích:**
- `locals`: biến cục bộ, dùng nội bộ trong module
- `"${var.environment}-${var.filename}"`: string interpolation
- `<<-EOT ... EOT`: heredoc syntax, viết multi-line string
- `path.module`: đường dẫn thư mục chứa file .tf hiện tại
- `resource "local_file"`: tạo file trên máy local
- Resource thứ 2 (`summary`) cho thấy 1 config có thể tạo nhiều resource

---

## Bước 4: Tạo file outputs.tf

```hcl
output "file_path" {
  description = "Đường dẫn file đã tạo"
  value       = local_file.hello.filename
}

output "summary_path" {
  description = "Đường dẫn file summary"
  value       = local_file.summary.filename
}

output "full_filename" {
  description = "Tên file đầy đủ"
  value       = local.full_filename
}
```

**Giải thích:**
- Output in ra kết quả sau `terraform apply`
- `local_file.hello.filename`: tham chiếu attribute của resource
- Format: `<resource_type>.<resource_name>.<attribute>`

---

## Bước 5: Chạy Terraform

Mở terminal tại thư mục exercise này, chạy lần lượt:

```bash
# 1. Khởi tạo — tải provider
terraform init

# 2. Format code
terraform fmt

# 3. Kiểm tra syntax
terraform validate

# 4. Xem plan — Terraform sẽ làm gì
terraform plan

# 5. Thực thi — tạo file
terraform apply

# 6. Xem output
terraform output

# 7. Xem file đã tạo
cat output/dev-hello.txt
cat output/summary.txt
```

---

## Bước 6: Thử thay đổi

Thử apply với variable khác:

```bash
terraform apply -var="environment=staging" -var="content=Xin chao Terraform"
```

Quan sát:
- Terraform plan hiện gì? (thêm/sửa/xoá bao nhiêu resource?)
- File tạo ra có gì khác?

---

## Bước 7: Xoá resource

```bash
terraform destroy
```

Quan sát:
- Terraform xoá những gì?
- Thư mục output còn không?

---

## Bước 8: Tìm hiểu State

Sau khi apply, mở file `terraform.tfstate` và trả lời:

1. File này lưu gì?
2. Tại sao Terraform cần file này?
3. Có nên commit file này lên Git không? Tại sao?

> **Gợi ý:** File `.gitignore` đã ignore `*.tfstate` — đó là best practice.

---

## Checklist Exercise 1

- [ ] Chạy `terraform init` thành công
- [ ] Chạy `terraform plan` và đọc hiểu output
- [ ] Chạy `terraform apply` tạo file thành công
- [ ] Đọc file `output/dev-hello.txt` thấy nội dung đúng
- [ ] Thử apply với variable khác
- [ ] Chạy `terraform destroy` xoá thành công
- [ ] Mở `terraform.tfstate` và hiểu nó lưu gì
