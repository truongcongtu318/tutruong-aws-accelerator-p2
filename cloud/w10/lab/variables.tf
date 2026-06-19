variable "aws_region" {
  description = "AWS region to deploy the lab resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for all lab resources."
  type        = string
  default     = "w10-macie-lab"
}

variable "alert_email" {
  description = "Email address that receives Amazon Macie alerts via SNS. You must confirm the subscription email after terraform apply."
  type        = string
}

variable "sample_sensitive_file_path" {
  description = "Local path to the sample sensitive-data file (e.g. credit-card numbers, PII) to be uploaded to S3 for Macie detection."
  type        = string
  default     = "sample-data/sensitive.txt"
}

variable "sample_clean_file_path" {
  description = "Local path to a clean sample file without sensitive data."
  type        = string
  default     = "sample-data/clean.txt"
}

variable "common_tags" {
  description = "Common tags added to all supported resources."
  type        = map(string)
  default = {
    Lab       = "aws-macie-sns"
    ManagedBy = "terraform"
    Project   = "w10-secure-operate"
  }
}
