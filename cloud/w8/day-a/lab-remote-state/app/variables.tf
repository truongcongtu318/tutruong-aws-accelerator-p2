variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-west-2"
}

variable "prefix" {
  description = "Prefix for resource naming."
  type        = string
  default     = "student"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of resources."
  type        = string
  default     = "student"
}

variable "instance_name" {
  description = "Name tag for the EC2 Instance."
  type        = string
  default     = "remote-state-app"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}
