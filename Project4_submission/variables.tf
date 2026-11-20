variable "user_name" {
  description = "Name of the IAM user"
  type        = string
  default     = "shlok-s3-reader"
}
 
variable "s3_read_policy" {
  description = "S3 read-only policy document (JSON)"
  type        = string
  default     = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}
