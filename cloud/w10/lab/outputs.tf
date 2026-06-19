output "s3_bucket_name" {
  description = "The name of the S3 bucket created to hold the files."
  value       = aws_s3_bucket.macie_target.id
}

output "macie_classification_job_id" {
  description = "The ID of the Amazon Macie classification job."
  value       = aws_macie2_classification_job.s3_scan.id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic that sends alerts."
  value       = aws_sns_topic.macie_alerts.arn
}

output "event_rule_arn" {
  description = "The ARN of the EventBridge rule catching Macie findings."
  value       = aws_cloudwatch_event_rule.macie_finding_rule.arn
}

output "macie_console_url" {
  description = "AWS Console URL for Amazon Macie."
  value       = "https://${var.aws_region}.console.aws.amazon.com/macie/home?region=${var.aws_region}#findings"
}

output "sns_confirm_instructions" {
  description = "Instructions to verify SNS email subscription."
  value       = "Please check the mailbox of '${var.alert_email}' and click 'Confirm Subscription' in the email from AWS Notifications before triggering Macie."
}
