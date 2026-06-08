terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # TODO: Cấu hình block backend "s3" lưu trữ state tập trung và khóa lock đồng thời.
  # Hãy thay thế các giá trị bên dưới bằng output của phần bootstrap.
  backend "s3" {
    bucket         = "tfstate-student-dev-66ba5173"
    key            = "w8-day-a/app/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tfstate-locks-student-dev"
    encrypt        = true
  }
}
