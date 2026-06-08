output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for the app"
  value       = aws_s3_bucket.app_bucket.id
}
