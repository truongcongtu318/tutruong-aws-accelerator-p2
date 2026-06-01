terraform {

  cloud {
    
    organization = "tutruong"

    workspaces {
      name = "learn-terraform"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.47.0"
    }
  }
  required_version = ">= 1.1"
}