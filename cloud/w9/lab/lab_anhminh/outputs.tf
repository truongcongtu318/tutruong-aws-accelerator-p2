output "instance_id" {
  description = "ID of the EC2 instance created for the lab."
  value       = aws_instance.monitoring_lab.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance."
  value       = aws_instance.monitoring_lab.public_ip
}

output "sns_topic_arn" {
  description = "SNS topic ARN used by the CPU alarm."
  value       = aws_sns_topic.cpu_alarm.arn
}

output "cpu_alarm_name" {
  description = "CloudWatch CPU alarm name."
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "ssm_start_session_command" {
  description = "Command to connect to the instance using SSM Session Manager."
  value       = "aws ssm start-session --region ${var.aws_region} --target ${aws_instance.monitoring_lab.id}"
}

output "cpu_stress_test_command" {
  description = "Command you can run inside EC2 to test the CPU alarm. Stop it with Ctrl+C."
  value       = "sudo dnf install -y stress-ng || sudo yum install -y stress-ng; stress-ng --cpu 2 --timeout 10m --metrics-brief"
}

output "cloudwatch_dashboard_url" {
  description = "AWS Console URL of the created CloudWatch Dashboard."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# ── Root Account Login Alarm (Lab 3) ──

output "trail_name" {
  description = "CloudTrail trail name for root login monitoring."
  value       = aws_cloudtrail.main.name
}

output "metric_filter_name" {
  description = "CloudWatch Logs Metric Filter for root login detection."
  value       = aws_cloudwatch_log_metric_filter.root_login.name
}

output "root_login_alarm_name" {
  description = "CloudWatch alarm name for root account login."
  value       = aws_cloudwatch_metric_alarm.root_login_alarm.alarm_name
}

output "root_login_sns_topic_arn" {
  description = "SNS topic ARN for root login alerts."
  value       = aws_sns_topic.root_login_alerts.arn
}

