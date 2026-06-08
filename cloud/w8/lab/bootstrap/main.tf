# Tài nguyên lưu trữ State & Lock (Tạo thủ công hoặc qua bootstrap)
# Sử dụng để tạo S3 Bucket và DynamoDB Table làm nơi lưu trữ Remote Backend của dự án.

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "tutruong-terraform-state-w8-lab"
  force_destroy = true # Cho phép xóa dễ dàng khi dọn dẹp lab

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Lab"
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_pab" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "tutruong-terraform-state-lock-w8-lab"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Lab"
  }
}
