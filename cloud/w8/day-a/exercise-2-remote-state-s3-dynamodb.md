# Bài thực hành 2: Terraform Remote State với AWS S3 và DynamoDB

## 1. Giới thiệu & Mục tiêu bài lab

Trong môi trường thực tế, **không bao giờ** lưu trữ file `terraform.tfstate` ở máy cá nhân (Local State) khi làm việc nhóm hoặc chạy production. Thay vào đó, ta sử dụng **Remote State** (Remote Backend) để lưu trữ tập trung file state trên Cloud (ví dụ AWS S3) và quản lý việc ghi đè đồng thời qua cơ chế khóa (State Locking) bằng DynamoDB.

**Mục tiêu bài lab này giúp bạn:**
1. Hiểu và tự tay viết mã nguồn HCL để xây dựng hạ tầng Remote Backend chuẩn production (S3 + DynamoDB).
2. Nắm vững cấu trúc phân tách giữa hạ tầng quản lý state (`bootstrap/`) và hạ tầng ứng dụng (`app/`).
3. Thực hành di chuyển (migrate) state từ local lên remote.
4. Kiểm chứng cơ chế khóa state (State Locking) để tránh conflict khi nhiều người chạy apply cùng lúc.
5. Thực hành dọn dẹp tài nguyên an toàn có cấu hình chống xóa (`prevent_destroy`).

---

## 2. Cách thực hiện tự viết HCL (Exercise Mode)

Để giúp bạn tự học và hiểu sâu cú pháp HCL (HCL syntax) của Terraform, các file cấu hình trong lab này được chia thành hai loại:
1.  **Các file `.tf` bài tập (Khung xương - Skeleton):** Nằm trong các thư mục `bootstrap/` và `app/`. Các file này đã được dựng sẵn khung sườn cấu trúc hoặc các ghi chú `# TODO`. Bạn cần mở các file này ra và tự tay viết code cấu hình theo hướng dẫn.
2.  **Các file giải pháp `.tf.solution`:** Đi kèm bên cạnh mỗi file bài tập để giúp bạn đối chiếu cú pháp hoặc tìm lỗi khi code của bạn không chạy được.

> [!TIP]
> Hãy cố gắng tự viết code dựa trên tài liệu hướng dẫn và gợi ý trong file `.tf` trước khi mở các file giải pháp `.tf.solution` để đối chiếu!

---

## 3. Các Best Practices được áp dụng

Bài lab này tuân thủ các nguyên tắc thiết kế hạ tầng Terraform an toàn và chuyên nghiệp:

*   **S3 Bucket Versioning (Bật):** Lưu lại toàn bộ lịch sử các phiên bản của file state. Nếu file state bị ghi đè lỗi hoặc bị hỏng, ta có thể khôi phục lại phiên bản cũ.
*   **S3 SSE-S3 Encryption (Mã hóa):** Mã hóa file state ở chế độ lưu trữ (at-rest). File state thường chứa thông tin nhạy cảm (secrets, mật khẩu, IP private).
*   **S3 Block Public Access (Chặn truy cập công cộng):** Chặn hoàn toàn mọi quyền truy cập từ Internet vào bucket chứa state.
*   **DynamoDB State Locking:** Sử dụng bảng DynamoDB có partition key duy nhất là `LockID` (bắt buộc) để khóa file state khi có lệnh ghi (`apply`/`destroy`) đang chạy.
*   **Separation of Concerns (Phân tách trách nhiệm):** Dự án được chia làm 2 thư mục độc lập:
    *   `bootstrap/`: Tạo S3 và DynamoDB (lưu state tại local).
    *   `app/`: Tạo VPC, EC2 và sử dụng S3 + DynamoDB vừa tạo làm Remote Backend.

---

## 4. Hướng dẫn từng bước thực hiện

### Bước 1: Tự viết code cho phần `bootstrap`

Hãy di chuyển vào thư mục `cloud/w8/day-a/lab-remote-state/bootstrap/`. Mở các file sau và hoàn thành các phần ghi chú `# TODO`:

1.  **[variables.tf](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/variables.tf)**: Khai báo 4 variables: `aws_region`, `prefix`, `environment`, `owner`. Tự viết kiểu dữ liệu (`type`), mô tả (`description`) và giá trị mặc định (`default`).
2.  **[main.tf](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/main.tf)**:
    *   Khai báo block local `name_suffix` và `common_tags`.
    *   Khai báo resource sinh chuỗi ngẫu nhiên `random_id`.
    *   Khai báo resource `aws_s3_bucket` có cấu hình chống xóa `prevent_destroy = true`.
    *   Khai báo resource `aws_s3_bucket_versioning` kích hoạt versioning (`status = "Enabled"`).
    *   Khai báo resource mã hóa `aws_s3_bucket_server_side_encryption_configuration` dùng mã hóa `AES256`.
    *   Khai báo block public access `aws_s3_bucket_public_access_block` chặn hoàn toàn truy cập public.
    *   Khai báo resource `aws_dynamodb_table` với partition key (hash_key) là `LockID` (kiểu dữ liệu String `S`).
3.  **[outputs.tf](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/outputs.tf)**: Trả về tên S3 Bucket (`aws_s3_bucket.state.id`) và tên DynamoDB table (`aws_dynamodb_table.locks.name`).

> [!NOTE]
> Bạn có thể xem lời giải mẫu tại các file: [main.tf.solution](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/main.tf.solution), [variables.tf.solution](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/variables.tf.solution), và [outputs.tf.solution](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/bootstrap/outputs.tf.solution).

---

### Bước 2: Deploy tài nguyên `bootstrap` từ Local

1. Copy file variable mẫu và sửa giá trị theo ý muốn:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Khởi tạo working directory để tải AWS và Random Provider:
   ```bash
   terraform init
   ```
3. Kiểm tra format và validate cú pháp HCL bạn vừa tự viết:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```
4. Xem dự thảo thay đổi hạ tầng và tiến hành deploy:
   ```bash
   terraform plan
   terraform apply
   ```
   *Nhập `yes` để xác nhận.*
5. Kiểm tra giá trị outputs hiển thị ở CLI sau khi apply thành công. Copy lại tên S3 bucket và DynamoDB table để cấu hình cho Bước 3.

---

### Bước 3: Cấu hình và Deploy phần `app` dùng Remote Backend

Bây giờ ta chuyển sang thư mục `cloud/w8/day-a/lab-remote-state/app/`.

Mở các file sau và hoàn thành các phần ghi chú `# TODO`:

1.  **[terraform.tf](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/app/terraform.tf)**: Điền cấu hình block `backend "s3"`. Điền cứng trực tiếp tên bucket, key, region, và dynamodb_table đã tạo ở Bước 2.
    *   *Lưu ý: Block backend không hỗ trợ sử dụng biến.*
2.  **[main.tf](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/app/main.tf)**:
    *   Tự viết định nghĩa module `vpc` sử dụng module registry `"terraform-aws-modules/vpc/aws"` phiên bản `"6.3.0"`.
    *   Định nghĩa resource `aws_instance` nằm trong private subnet đầu tiên của VPC vừa tạo.

> [!NOTE]
> Bạn có thể xem lời giải mẫu tại các file: [terraform.tf.solution](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/app/terraform.tf.solution) và [main.tf.solution](file:///c:/Users/tct31/project/tutruong-aws-accelerator-p2/cloud/w8/day-a/lab-remote-state/app/main.tf.solution).

#### Thực thi deploy phần `app`:
1. Chạy lệnh khởi tạo. Lúc này Terraform sẽ cấu hình remote backend thay vì lưu ở local:
   ```bash
   terraform init
   ```
   *Bạn sẽ thấy thông báo: `Successfully configured the backend "s3"!`*
2. Chạy plan và apply để tạo VPC + EC2:
   ```bash
   terraform plan
   terraform apply
   ```
   *Xác nhận `yes`.*
3. Kiểm tra trong thư mục `app/`, bạn sẽ thấy **không có** file `terraform.tfstate` nào được tạo ra ở local. File state đã được upload trực tiếp lên S3 tại key `w8-day-a/app/terraform.tfstate`.

---

### Bước 4: Kiểm chứng cơ chế State Locking (Khóa State)

Để hiểu cách DynamoDB ngăn chặn xung đột ghi đè, hãy làm theo các bước sau:

1. Tại Terminal 1 (trong thư mục `app/`), hãy chạy lệnh apply:
   ```bash
   terraform apply
   ```
   *Dừng lại ở dấu nhắc hỏi xác nhận: `Do you want to perform these actions?` (không nhập gì cả).*
2. Mở một Terminal 2 độc lập trên máy của bạn, di chuyển đến thư mục `app/` và chạy lệnh plan:
   ```bash
   terraform plan
   ```
3. Quan sát kết quả ở Terminal 2:
   Bạn sẽ gặp một thông báo lỗi tương tự như thế này:
   ```text
   │ Error: Error acquiring the state lock
   │
   │ Error message: ConditionalCheckFailedException:
   │ Lock Info:
   │   ID:        e4c84db2-df65-1d45-728b-b184061a9bc9
   ```
4. Vào AWS Console → DynamoDB → Tables → Chọn bảng lock của bạn → tab "Explore items". Bạn sẽ nhìn thấy một dòng dữ liệu (Item) chứa thông tin LockID tương ứng với thông tin hiển thị lỗi ở Terminal 2.
5. Tại Terminal 1, hãy gõ `no` để hủy lệnh apply.
6. Chạy lại `terraform plan` ở Terminal 2. Lúc này lệnh sẽ chạy thành công vì lock đã được giải phóng.

---

### Bước 5: Kiểm chứng tính năng Versioning của S3 State

1. Sửa đổi nhỏ ở file `app/main.tf` (ví dụ: bổ sung một tag mới vào EC2 instance: `Environment = "dev"`).
2. Chạy apply tự động:
   ```bash
   terraform apply -auto-approve
   ```
3. Truy cập AWS Console → S3 → Vào bucket chứa state của bạn → Điều hướng tới file `w8-day-a/app/terraform.tfstate`.
4. Bật chế độ **"Show versions"** (Hiển thị phiên bản).
5. Bạn sẽ thấy ít nhất 2 phiên bản của file `terraform.tfstate` tương ứng với các lần apply trước và sau khi thêm tag. Điều này đảm bảo bạn có thể rollback dễ dàng nếu có sự cố xảy ra.

---

### Bước 6: Quy trình dọn dẹp tài nguyên (Destroy) an toàn

Do các tài nguyên S3 và DynamoDB của chúng ta có thuộc tính an toàn `prevent_destroy = true`, bạn cần thực hiện dọn dẹp theo thứ tự chuẩn xác để tránh lỗi:

#### 1. Xóa hạ tầng ứng dụng (`app/`):
Di chuyển tới thư mục `app/` và chạy lệnh xóa:
```bash
terraform destroy
```
*Xác nhận `yes`.*

#### 2. Xóa hạ tầng quản lý state (`bootstrap/`):
Di chuyển tới thư mục `bootstrap/`. Nếu bạn chạy `terraform destroy` trực tiếp lúc này, lệnh sẽ bị lỗi.

**Cách xử lý đúng:**
1. Vào AWS Console S3, chọn bucket chứa state, nhấn **Empty** để xóa hoàn toàn các đối tượng và tất cả các phiên bản (versions) của chúng bên trong bucket.
2. Mở file `bootstrap/main.tf` (hoặc solution), tìm block resource của S3 Bucket và DynamoDB Table, sửa đổi cấu hình lifecycle:
   ```hcl
   lifecycle {
     prevent_destroy = false # Chuyển từ true sang false
   }
   ```
3. Chạy lệnh destroy để gỡ bỏ hạ tầng bootstrap:
   ```bash
   terraform destroy
   ```
   *Xác nhận `yes`.*

---

## 5. Câu hỏi suy ngẫm cho Học viên

Sau khi hoàn thành bài lab, hãy tự trả lời các câu hỏi sau để củng cố kiến thức:
1. Tại sao ta không thể dùng biến kiểu `var.s3_bucket_name` bên trong block cấu hình `backend "s3"`?
2. Nếu mất quyền truy cập vào bảng DynamoDB lock (ví dụ IAM policy bị chặn), ta có chạy được lệnh `terraform plan` hay `terraform apply` không?
3. Nếu hai người dùng cùng chạy `terraform plan` cùng một lúc, chuyện gì sẽ xảy ra?
4. Điều gì sẽ xảy ra với file state nếu S3 Bucket không bật tính năng Versioning và một thành viên trong nhóm vô tình xóa nhầm hoặc chạy ghi đè một cấu hình rỗng?
