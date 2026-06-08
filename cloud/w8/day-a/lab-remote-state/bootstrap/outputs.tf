# Hướng dẫn: Khai báo các output để lấy thông tin cần thiết cấu hình cho phần app.

# TODO: Khai báo output "s3_bucket_name" trả về giá trị ID của S3 bucket "state"
output "s3_bucket_name" {
  description = "The name of the S3 bucket created for Terraform remote state."
  value       = aws_s3_bucket.state.id
}

# TODO: Khai báo output "dynamodb_table_name" trả về giá trị name của DynamoDB table "locks"
output "dynamodb_table_name" {
  description = "The name of the DynamoDB table created for state locking."
  value       = aws_dynamodb_table.locks.name
}

# TODO: Khai báo output "aws_region" trả về giá trị của biến aws_region
output "aws_region" {
  description = "The AWS Region used."
  value       = var.aws_region
}
