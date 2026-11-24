terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

resource "aws_vpc" "vpc" {
  cidr_block           = "10.99.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shlok-p17-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "shlok-p17-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.99.1.0/24"
  availability_zone       = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-p17-subnet" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "shlok-p17-rt" }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "web" {
  name   = "shlok-p17-web-sg"
  vpc_id = aws_vpc.vpc.id
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
  tags = { Name = "shlok-p17-web-sg" }
}

resource "aws_iam_role" "role" {
  name = "shlok-p17-cwagent-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "profile" {
  name = "shlok-p17-cwagent-profile"
  role = aws_iam_role.role.name
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "shlok-p17-logs"
  retention_in_days = 1
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  user_data = <<-USERDATA
    #!/bin/bash
    dnf install -y nginx amazon-cloudwatch-agent
    echo "<h1>Shlok Project 17 - log forwarding</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CFG'
    {
      "agent": { "run_as_user": "root" },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/nginx/access.log",
                "log_group_name": "shlok-p17-logs",
                "log_stream_name": "{instance_id}-nginx-access"
              },
              {
                "file_path": "/var/log/nginx/error.log",
                "log_group_name": "shlok-p17-logs",
                "log_stream_name": "{instance_id}-nginx-error"
              }
            ]
          }
        }
      }
    }
    CFG
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
    for i in 1 2 3 4 5; do curl -s localhost/ > /dev/null; curl -s localhost/missing > /dev/null; sleep 1; done
  USERDATA

  tags = { Name = "shlok-p17-web" }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
