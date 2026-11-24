# Project 19 - Scheduled S3 Backup
 
## Goal
Automate a backup routine: a cron job uploads logs to S3.
 
## What it does
- Terraform creates the S3 bucket shlok-p19-backup-<random>.
- backup.sh uploads the logs folder to s3://<bucket>/backups/<timestamp>/ using aws s3 cp --recursive.
- Cron runs backup.sh every 5 minutes: */5 * * * * /home/clouduser/Project19/backup.sh >> /home/clouduser/Project19/cron.log 2>&1
- Verified with aws s3 ls --recursive: several timestamped folders, each with application.log and system.log.
 
## Files
main.tf, backup.sh, .gitignore, .terraform.lock.hcl
