# Lab Anh Minh — CloudWatch Agent + CPU Alarm bằng Terraform

Thư mục này dựng lại từ đầu 2 lab trong slide bằng Terraform, bao gồm cả EC2 mới.

## Lab được triển khai

### 1. Installing the CloudWatch Agent on EC2

Terraform tạo:

- 1 EC2 Amazon Linux 2023.
- IAM Role + Instance Profile cho EC2.
- Gắn policy:
  - `AmazonSSMManagedInstanceCore`
  - `CloudWatchAgentServerPolicy`
- User data cài package `amazon-cloudwatch-agent`.
- Tạo config agent để gửi metric CPU, memory, disk lên namespace `CWAgent`.
- Start và enable service `amazon-cloudwatch-agent`.

### 2. CPU Alarm gửi Email Alert qua SNS

Terraform tạo:

- SNS Topic.
- Email subscription tới địa chỉ bạn nhập.
- CloudWatch Alarm cho EC2 vừa tạo:
  - Metric: `AWS/EC2 CPUUtilization`
  - Threshold: `> 80%`
  - Period: `300` giây
  - Evaluation: `1` datapoint
  - Alarm action: gửi email qua SNS
  - OK action: gửi email khi recover

> Lưu ý: sau khi `terraform apply`, bạn phải mở email và bấm **Confirm subscription** thì SNS mới gửi mail được.

## Files

```text
.
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── user_data_cloudwatch_agent.sh
├── terraform.tfvars.example
└── README.md
```

## Cách chạy

```bash
cd cloud/w9/lab/lab_anhminh
cp terraform.tfvars.example terraform.tfvars
```

Sửa file `terraform.tfvars`:

```hcl
aws_region  = "ap-southeast-1"
project_name = "lab-anhminh-monitoring"
alert_email  = "your-email@example.com"

instance_type = "t3.micro"
key_name         = null
ssh_allowed_cidr = null
```

Deploy:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## Kết nối vào EC2

Khuyến nghị dùng SSM Session Manager, không cần mở SSH:

```bash
aws ssm start-session --region ap-southeast-1 --target <instance_id>
```

Hoặc lấy lệnh chính xác từ output:

```bash
terraform output ssm_start_session_command
```

## Kiểm tra CloudWatch Agent trên EC2

Sau khi vào EC2 bằng SSM:

```bash
sudo systemctl status amazon-cloudwatch-agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
sudo tail -n 100 /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log
```

Trong AWS Console:

```text
CloudWatch -> Metrics -> All metrics -> CWAgent
```

## Test CPU Alarm

Vào EC2 rồi chạy:

```bash
sudo dnf install -y stress-ng || sudo yum install -y stress-ng
stress-ng --cpu 2 --timeout 10m --metrics-brief
```

Đợi khoảng 5 phút để alarm chuyển sang `ALARM` và gửi email.

Kiểm tra bằng AWS CLI:

```bash
aws cloudwatch describe-alarms \
  --region ap-southeast-1 \
  --alarm-names lab-anhminh-monitoring-ec2-high-cpu
```

## Dọn dẹp

Khi làm xong lab để tránh phát sinh chi phí:

```bash
terraform destroy
```
