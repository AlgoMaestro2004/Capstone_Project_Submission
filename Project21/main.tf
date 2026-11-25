terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_availability_zones" "az" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
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

resource "aws_vpc" "main" {
  cidr_block           = "10.55.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shlok-p21-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "shlok-p21-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.55.1.0/24"
  availability_zone       = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-p21-subnet" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "shlok-p21-rt" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "web" {
  name   = "shlok-p21-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "shlok-p21-sg" }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = true
  user_data              = <<-USERDATA
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>Shlok Project 21 server</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  USERDATA
  tags                   = { Name = "shlok-p21-web" }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Shlok-Project21-Monitoring-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "EC2 CPU Utilization"
          region  = "ap-south-1"
          view    = "timeSeries"
          stat    = "Average"
          period  = 300
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web.id]]
          yAxis   = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Network In"
          region  = "ap-south-1"
          view    = "timeSeries"
          stat    = "Sum"
          period  = 300
          metrics = [["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web.id]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Network Out"
          region  = "ap-south-1"
          view    = "timeSeries"
          stat    = "Sum"
          period  = 300
          metrics = [["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web.id]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "EC2 Status Checks"
          region  = "ap-south-1"
          view    = "timeSeries"
          stat    = "Maximum"
          period  = 300
          metrics = [["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.web.id]]
          yAxis   = { left = { min = 0, max = 1 } }
        }
      }
    ]
  })
}

output "dashboard_url" {
  value = "https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards/dashboard/Shlok-Project21-Monitoring-Dashboard"
}
