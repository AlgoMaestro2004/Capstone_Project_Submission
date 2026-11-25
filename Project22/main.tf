terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}
 
provider "aws" {
  region = "ap-south-1"
}
 
resource "random_id" "suffix" {
  byte_length = 4
}
 
resource "aws_s3_bucket" "logs" {
  bucket        = "shlok-p22-logs-${random_id.suffix.hex}"
  force_destroy = true
}
 
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
 
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
 
    filter {
      prefix = "logs/"
    }
 
    expiration {
      days = 7
    }
  }
}
 
output "bucket_name" {
  value = aws_s3_bucket.logs.bucket
}
