provider "aws" {
  region = "ap-south-1"
}
 
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["terraform-vpc"]
  }
}
 
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
 
resource "aws_subnet" "monitor" {
  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = "10.0.214.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "shlok-monitor-subnet"
  }
}
 
resource "aws_security_group" "monitor" {
  name        = "shlok-monitor-sg"
  description = "Shlok CloudWatch project SG"
  vpc_id      = data.aws_vpc.existing.id
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "shlok-monitor-sg"
  }
}
 
resource "aws_instance" "monitor" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.monitor.id
  vpc_security_group_ids = [aws_security_group.monitor.id]
  monitoring             = true
 
  user_data = <<-EOT
    #!/bin/bash
    for i in 1 2; do
      setsid nohup timeout 1800 sh -c 'while :; do :; done' > /dev/null 2>&1 &
    done
  EOT
 
  tags = {
    Name = "shlok-monitor-server"
  }
}
 
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "shlok-high-cpu-alarm"
  alarm_description   = "CPU above 50 percent"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.monitor.id
  }
}
 
output "instance_id" {
  value = aws_instance.monitor.id
}
 
output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

