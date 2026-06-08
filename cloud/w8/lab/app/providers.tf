terraform {
  backend "s3" {
    bucket         = "tutruong-terraform-state-w8-lab"
    key            = "w8/lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tutruong-terraform-state-lock-w8-lab"
    encrypt        = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
