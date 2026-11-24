# Project 17 - Log Forwarding to CloudWatch
 
Terraform builds a VPC, a public subnet, and an EC2 running Nginx.
An IAM role (CloudWatchAgentServerPolicy) lets the EC2 write to CloudWatch.
The CloudWatch agent is installed at boot and ships the Nginx access and
error logs to the log group shlok-p17-logs.
 
Proof: aws logs filter-log-events shows the Nginx log lines.
