provider "aws" {
  region = "ap-south-1"
}
 
resource "aws_iam_policy" "s3_read" {
  name        = "shlok-s3-read-policy"
  description = "Read-only access to S3"
  policy      = var.s3_read_policy
}
 
resource "aws_iam_user" "reader" {
  name = var.user_name
}
 
resource "aws_iam_user_policy_attachment" "reader_s3" {
  user       = aws_iam_user.reader.name
  policy_arn = aws_iam_policy.s3_read.arn
}
 
output "user_name" {
  value = aws_iam_user.reader.name
}
 
output "policy_arn" {
  value = aws_iam_policy.s3_read.arn
}
