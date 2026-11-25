# Project 23 - IAM Role Based Access
 
## Goal
Secure resource usage: an EC2 reaches S3 through an IAM role, with no access keys on the server.
 
## What it does
- Terraform creates an S3 bucket shlok-p23-data-<random> with a test file hello.txt.
- IAM role shlok-p23-ec2-s3-read-role (trusted by ec2.amazonaws.com) with an inline policy: s3:ListBucket on the bucket and s3:GetObject on its objects only (read only).
- Instance profile attaches the role to the EC2 (AL2023, t3.micro, IMDSv2 required).
- Own VPC 10.99.0.0/16; sshd also listens on port 443 because outbound port 22 is blocked.
 
## CLI test (run on the EC2)
- aws sts get-caller-identity shows assumed-role/shlok-p23-ec2-s3-read-role.
- No ~/.aws/credentials file exists on the server.
- aws s3 ls and aws s3 cp of hello.txt work (read allowed).
- aws s3 cp t.txt to the bucket fails with AccessDenied for s3:PutObject (write denied).
 
## Files
main.tf, .gitignore, .terraform.lock.hcl
