data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  name = var.project_name
  tags = merge(var.common_tags, {
    Project = var.project_name
  })
}

resource "aws_iam_role" "ec2_cloudwatch" {
  name = "${local.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.ec2_cloudwatch.name

  tags = local.tags
}

resource "aws_security_group" "ec2" {
  name        = "${local.name}-sg"
  description = "Security group for CloudWatch monitoring lab EC2"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.key_name != null && var.ssh_allowed_cidr != null ? [1] : []

    content {
      description = "SSH from allowed CIDR"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  }

  egress {
    description = "Allow outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-sg"
  })
}

resource "aws_instance" "monitoring_lab" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_cloudwatch.name
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data_replace_on_change = true
  user_data                   = file("${path.module}/user_data_cloudwatch_agent.sh")

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-ec2"
  })

  depends_on = [
    aws_iam_role_policy_attachment.ssm_managed_instance,
    aws_iam_role_policy_attachment.cloudwatch_agent
  ]
}

resource "aws_sns_topic" "cpu_alarm" {
  name = "${local.name}-cpu-alarm-topic"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name}-ec2-high-cpu"
  alarm_description   = "Send email via SNS when EC2 CPU is greater than ${var.cpu_alarm_threshold}% for 5 minutes."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_alarm_threshold
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.monitoring_lab.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm.arn]
  ok_actions    = [aws_sns_topic.cpu_alarm.arn]

  tags = local.tags
}

# ─────────────────────────────────────────────────────────────
# Lab 3: CloudWatch Dashboard
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ── CPU usage widget ──
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU Utilization"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.monitoring_lab.id]
          ]
          annotations = {
            horizontal = [
              {
                label = "Alarm threshold (${var.cpu_alarm_threshold}%)"
                value = var.cpu_alarm_threshold
                color = "#d62728"
                fill  = "above"
              }
            ]
          }
        }
      },

      # ── CPU from CWAgent namespace ──
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CWAgent — CPU usage (idle, user, system, iowait)"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["CWAgent", "cpu_usage_idle", "InstanceId", aws_instance.monitoring_lab.id, { yAxis = "left" }],
            ["CWAgent", "cpu_usage_user", "InstanceId", aws_instance.monitoring_lab.id, { yAxis = "left" }],
            ["CWAgent", "cpu_usage_system", "InstanceId", aws_instance.monitoring_lab.id, { yAxis = "left" }],
            ["CWAgent", "cpu_usage_iowait", "InstanceId", aws_instance.monitoring_lab.id, { yAxis = "left" }],
          ]
        }
      },

      # ── Memory widget ──
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "CWAgent — Memory Used %"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["CWAgent", "mem_used_percent", "InstanceId", aws_instance.monitoring_lab.id]
          ]
        }
      },

      # ── Disk widget ──
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "CWAgent — Disk Used %"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.monitoring_lab.id, { yAxis = "left" }]
          ]
        }
      },

      # ── Alarm status widget ──
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "CPU Alarm Status"
          alarms = [aws_cloudwatch_metric_alarm.high_cpu.arn]
        }
      }
    ]
  })
}

