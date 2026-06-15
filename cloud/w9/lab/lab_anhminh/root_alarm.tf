# Get current AWS account details
data "aws_caller_identity" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 1. S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${local.name}-cloudtrail-${random_string.suffix.result}"
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 2. CloudWatch Logs Group for CloudTrail Logs
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${local.name}-logs"
  retention_in_days = 7

  tags = local.tags
}

# IAM Role for CloudTrail to send logs to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "${local.name}-cloudtrail-to-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  name = "${local.name}-cloudtrail-to-cw-policy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# 3. CloudTrail Config
resource "aws_cloudtrail" "main" {
  name                          = "${local.name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true # Root account login events are sent to us-east-1 first but multi-region trail captures it everywhere.
  enable_log_file_validation    = true

  cloud_watch_logs_role_arn      = aws_iam_role.cloudtrail_to_cloudwatch.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"

  depends_on = [
    aws_s3_bucket_policy.cloudtrail
  ]

  tags = local.tags
}

# 4. Metric Filter for Root Account Login
resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "RootAccountLoginFilter"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "RootAccountLoginCount"
    namespace = "Security"
    value     = "1"
  }
}

# 5. SNS Topic for Root Login Alerts
resource "aws_sns_topic" "root_login_alerts" {
  name = "${local.name}-root-login-alerts-topic"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "root_login_email" {
  topic_arn = aws_sns_topic.root_login_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 6. CloudWatch Metric Alarm for Root Login
resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "${local.name}-root-login-alarm"
  alarm_description   = "Trigger alarm immediately when AWS Root account login is detected."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountLoginCount"
  namespace           = "Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.root_login_alerts.arn]

  tags = local.tags
}
