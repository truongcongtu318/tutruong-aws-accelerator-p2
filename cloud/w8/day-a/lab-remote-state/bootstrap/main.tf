locals {
  name_suffix = "${var.prefix}-${var.environment}"

  # TODO: Khai báo các common tag bao gồm Project, Environment, Owner, ManagedBy
  common_tags = {
    Project     = "terraform-remote-state"
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

# TODO: Khai báo resource random_id "bucket_suffix" có byte_length = 4 để tạo chuỗi ngẫu nhiên
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# TODO: Định nghĩa resource "aws_s3_bucket" "state"
# - bucket: dùng định dạng "tfstate-${local.name_suffix}-${random_id.bucket_suffix.hex}"
# - force_destroy: false
# - lifecycle: ngăn chặn xóa tài nguyên bằng thuộc tính prevent_destroy = true
resource "aws_s3_bucket" "state" {
  bucket        = "tfstate-${local.name_suffix}-${random_id.bucket_suffix.hex}"
  force_destroy = false
  lifecycle {
    prevent_destroy = false
  }
  tags = local.common_tags
}

# TODO: Định nghĩa resource "aws_s3_bucket_versioning" "state"
# - bucket: tham chiếu tới ID của bucket vừa tạo ở trên
# - versioning_configuration: đặt status là "Enabled"
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# TODO: Định nghĩa resource "aws_s3_bucket_server_side_encryption_configuration" "state"
# - bucket: tham chiếu tới ID của bucket
# - rule: apply server-side encryption AES256 mặc định
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# TODO: Định nghĩa resource "aws_s3_bucket_public_access_block" "state" để chặn truy cập public
# - bucket: tham chiếu tới ID của bucket
# - Đặt block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets = true
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TODO: Định nghĩa resource "aws_dynamodb_table" "locks"
# - name: "tfstate-locks-${local.name_suffix}"
# - billing_mode: "PAY_PER_REQUEST"
# - hash_key: "LockID" (Bắt buộc)
# - attribute: đặt name = "LockID" và type = "S" (String)
# - lifecycle: ngăn chặn xóa bảng bằng thuộc tính prevent_destroy = true
resource "aws_dynamodb_table" "locks" {
  name         = "tfstate-locks-${local.name_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = false
  }
  tags = local.common_tags
}
