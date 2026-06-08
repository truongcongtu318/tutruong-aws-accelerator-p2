terraform {
  backend "s3" {
    bucket         = "tutruong-terraform-state-w8-lab"
    key            = "w8/lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tutruong-terraform-state-lock-w8-lab" 
    encrypt        = true
  }
}