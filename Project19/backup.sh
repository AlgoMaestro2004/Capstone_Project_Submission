#!/bin/bash
BUCKET="shlok-p19-backup-a1c1e91c"
LOGDIR="/home/clouduser/Project19/logs"
TS=$(date +%Y-%m-%d_%H-%M-%S)
aws s3 cp "$LOGDIR" "s3://$BUCKET/backups/$TS/" --recursive
echo "Backup completed at $TS"
