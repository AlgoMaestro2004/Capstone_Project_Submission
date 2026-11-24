terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.77.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shlok-ansible-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "shlok-ansible-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.77.1.0/24"
  map_public_ip_on_launch = true
  tags                    = { Name = "shlok-ansible-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "shlok-ansible-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "target" {
  name        = "shlok-ansible-sg"
  description = "SSH on 443 and HTTP 80"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = { Name = "shlok-ansible-sg" }
}

resource "aws_key_pair" "ansible" {
  key_name   = "shlok-ansible-key"
  public_key = file(pathexpand("~/.ssh/shlok-ansible-key.pub"))
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "target" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.target.id]
  key_name               = aws_key_pair.ansible.key_name

  user_data = <<-USERDATA
    #!/bin/bash
    printf "Port 22\nPort 443\n" > /etc/ssh/sshd_config.d/99-port443.conf
    systemctl restart sshd
  USERDATA

  user_data_replace_on_change = true

  tags = { Name = "shlok-ansible-target" }
}

output "target_public_ip" {
  value = aws_instance.target.public_ip
}
