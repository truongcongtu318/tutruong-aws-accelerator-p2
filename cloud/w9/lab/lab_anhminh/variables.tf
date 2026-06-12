variable "aws_region" {
  description = "AWS region to deploy the lab resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for all lab resources."
  type        = string
  default     = "lab-anhminh-monitoring"
}

variable "alert_email" {
  description = "Email address that receives SNS alarm notifications. You must confirm the subscription email after terraform apply."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the monitoring lab."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access. Leave null if you only use SSM Session Manager."
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the instance when key_name is set. Keep this narrow, for example your_public_ip/32."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 8
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage that triggers the CloudWatch alarm."
  type        = number
  default     = 80
}

variable "common_tags" {
  description = "Common tags added to all supported resources."
  type        = map(string)
  default = {
    Lab       = "aws-monitoring"
    ManagedBy = "terraform"
  }
}
