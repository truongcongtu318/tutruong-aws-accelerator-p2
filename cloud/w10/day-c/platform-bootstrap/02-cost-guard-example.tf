# AWS Cost Anomaly Detection — Terraform / CloudFormation Config mẫu
# File này minh hoạ cấu hình phát hiện chi phí bất thường trên AWS

# Ghi chú: Đây là cấu trúc tham khảo bằng Terraform HCL và CloudFormation
# Trong lab W10, bạn có thể tạo trên AWS Console hoặc dùng CLI.

# -------------------- Cách tạo bằng Terraform --------------------
# resource "aws_ce_anomaly_monitor" "daily_cost" {
#   name              = "W10-Daily-Cost-Monitor"
#   monitor_type      = "DIMENSIONAL"
#   monitor_dimension = "SERVICE"
#
#   monitor_specification {
#     Tags {
#       Key   = "Environment"
#       Value = "Production"
#     }
#   }
# }
#
# resource "aws_ce_anomaly_subscription" "email_alert" {
#   name      = "W10-Cost-Alert"
#   frequency = "DAILY"
#   monitor_arn_list = [aws_ce_anomaly_monitor.daily_cost.arn]
#   subscribers {
#     type    = "EMAIL"
#     address = "your-email@example.com"
#   }
#   threshold = 30  # Cảnh báo khi cost spike > 30%
# }
# -------------------- Kết thúc Terraform --------------------
