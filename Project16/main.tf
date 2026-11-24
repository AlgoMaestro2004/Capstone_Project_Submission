terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
 
provider "aws" {
  region = "ap-south-1"
}
 
data "aws_availability_zones" "available" {
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
    values = ["al2023-ami-2023*-x86_64"]
  }
}
 
resource "aws_vpc" "main" {
  cidr_block           = "10.88.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shlok-p16-vpc" }
}
 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "shlok-p16-igw" }
}
 
resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.88.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-p16-subnet-a" }
}
 
resource "aws_subnet" "b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.88.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-p16-subnet-b" }
}
 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "shlok-p16-rt" }
}
 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.a.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.b.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_security_group" "alb" {
  name   = "shlok-p16-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "shlok-p16-alb-sg" }
}
 
resource "aws_security_group" "web" {
  name   = "shlok-p16-web-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "shlok-p16-web-sg" }
}
 
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = <<-USERDATA
    #!/bin/bash
    dnf install -y nginx
    echo '<h1>Shlok - Project 16 - Secure HTTPS via ALB and ACM</h1>' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  USERDATA
  tags                   = { Name = "shlok-p16-web" }
}
 
resource "tls_private_key" "cert" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
 
resource "tls_self_signed_cert" "cert" {
  private_key_pem       = tls_private_key.cert.private_key_pem
  validity_period_hours = 8760
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
  dns_names             = ["shlok-p16.example.com"]
  subject {
    common_name = "shlok-p16.example.com"
  }
}
 
resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.cert.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
  tags             = { Name = "shlok-p16-cert" }
}
 
resource "aws_lb_target_group" "tg" {
  name     = "shlok-p16-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/"
  }
}
 
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}
 
resource "aws_lb" "alb" {
  name               = "shlok-p16-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.a.id, aws_subnet.b.id]
  tags               = { Name = "shlok-p16-alb" }
}
 
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
 
resource "aws_lb_listener" "http_block" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HTTP traffic blocked - use HTTPS"
      status_code  = "403"
    }
  }
}
 
output "alb_dns" {
  value = aws_lb.alb.dns_name
}
