# Hướng dẫn: Khai báo các biến đầu vào cho vùng chạy AWS, prefix đặt tên và tags.

# TODO: Khai báo variable "aws_region" kiểu string và default là "us-west-2"
variable "aws_region" {
  # Viết code của bạn ở đây:
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

# TODO: Khai báo variable "prefix" kiểu string để đặt tiền tố tên các tài nguyên và default là "student"
variable "prefix" {
  description = "Prefix"
  type        = string
  default     = "student"
}

# TODO: Khai báo variable "environment" kiểu string (ví dụ: dev, staging, prod) và default là "dev"
variable "environment" {
  # Viết code của bạn ở đây
  description = "Environment"
  type        = string
  default     = "dev"
}

# TODO: Khai báo variable "owner" kiểu string để gán tag người sở hữu và default là "student"
variable "owner" {
  # Viết code của bạn ở đây
  description = "Owner"
  type        = string
  default     = "student"
}
