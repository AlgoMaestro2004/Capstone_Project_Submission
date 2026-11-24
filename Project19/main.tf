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
 
resource "aws_s3_bucket" "backup" {
  bucket        = "shlok-p19-backup-${random_id.suffix.hex}"
  force_destroy = true
}
 
output "bucket_name" {
  value = aws_s3_bucket.backup.bucket
}
