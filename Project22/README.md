# Project 22 - S3 Log Archive with Lifecycle
 
## Goal
Lower storage cost by deleting old logs automatically.
 
## What it does
- Terraform creates the S3 bucket shlok-p22-logs-<random> and a lifecycle rule.
- Rule expire-old-logs: prefix logs/, expiration after 7 days, status Enabled.
- Sample logs (app, access, system) were uploaded to s3://<bucket>/logs/ with aws s3 cp --recursive.
- Verified with aws s3 ls and aws s3api get-bucket-lifecycle-configuration.
 
## Files
main.tf, .gitignore, .terraform.lock.hcl
