terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
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
 
resource "random_id" "suffix" {
  byte_length = 4
}
 
resource "aws_s3_bucket" "data" {
  bucket        = "shlok-p23-data-${random_id.suffix.hex}"
  force_destroy = true
}
 
resource "aws_s3_object" "hello" {
  bucket  = aws_s3_bucket.data.id
  key     = "hello.txt"
  content = "Hello from Shlok's secure bucket"
}
 
resource "aws_vpc" "main" {
  cidr_block           = "10.99.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shlok-p23-vpc" }
}
 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "shlok-p23-igw" }
}
 
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.99.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-p23-subnet" }
}
 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "shlok-p23-rt" }
}
 
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_security_group" "ssh443" {
  name        = "shlok-p23-sg"
  description = "SSH on port 443"
  vpc_id      = aws_vpc.main.id
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
  tags = { Name = "shlok-p23-sg" }
}
 
resource "aws_key_pair" "key" {
  key_name   = "shlok-iam-key"
  public_key = file("/home/clouduser/.ssh/shlok-iam-key.pub")
}
 
resource "aws_iam_role" "ec2" {
  name = "shlok-p23-ec2-s3-read-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
 
resource "aws_iam_role_policy" "s3_read" {
  name = "shlok-p23-s3-read-only"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.data.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.data.arn}/*"
      }
    ]
  })
}
 
resource "aws_iam_instance_profile" "ec2" {
  name = "shlok-p23-instance-profile"
  role = aws_iam_role.ec2.name
}
 
resource "aws_instance" "server" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh443.id]
  key_name               = aws_key_pair.key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
 
  metadata_options {
    http_tokens = "required"
  }
 
  user_data = <<-EOT
    #!/bin/bash
    mkdir -p /etc/ssh/sshd_config.d
    printf 'Port 22\nPort 443\n' > /etc/ssh/sshd_config.d/99-port443.conf
    systemctl restart sshd
  EOT
 
  tags = { Name = "shlok-p23-server" }
}
 
output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}
 
output "server_ip" {
  value = aws_instance.server.public_ip
}
