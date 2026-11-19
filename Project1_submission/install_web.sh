#!/bin/bash
dnf install -y httpd
systemctl enable --now httpd
echo "<h1>Hello from Terraform on AWS EC2</h1>" > /var/www/html/index.html
