locals {
  name_prefix = "${var.prefix}-${var.environment}"

  common_tags = {
    Project     = "terraform-remote-state-lab"
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

# Lấy thông tin AMI mới nhất của Ubuntu 24.04 từ AWS Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

# TODO: Định nghĩa module "vpc" sử dụng module registry "terraform-aws-modules/vpc/aws"
# - version: "6.3.0"
# - name: "${local.name_prefix}-vpc"
# - cidr: "10.0.0.0/16"
# - azs: ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
# - public_subnets: ["10.0.1.0/24", "10.0.2.0/24"]
# - private_subnets: ["10.0.3.0/24"]
# - enable_dns_hostnames: true
# - enable_dns_support: true
# - tags: gán tag local.common_tags
module "vpc" {
  version = "6.3.0"
  source  = "terraform-aws-modules/vpc/aws"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# TODO: Định nghĩa resource "aws_instance" "app_server"
# - ami: tham chiếu tới ID của data source "ubuntu" lấy được ở trên
# - instance_type: tham chiếu tới biến var.instance_type
# - vpc_security_group_ids: tham chiếu tới default security group của VPC (sử dụng: [module.vpc.default_security_group_id])
# - subnet_id: đặt instance vào private subnet đầu tiên của VPC (sử dụng: module.vpc.private_subnets[0])
# - tags: merge tag local.common_tags với tag Name là "${local.name_prefix}-${var.instance_name}"
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]
  tags                   = merge(local.common_tags, { Name = "${local.name_prefix}-${var.instance_name}" })
}
