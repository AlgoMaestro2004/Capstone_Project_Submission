# Project 16: Enable HTTPS using ACM
 
Terraform builds a VPC with 2 public subnets, an internet-facing ALB,
and one Nginx EC2 server. The server only accepts traffic from the ALB.
 
- Certificate: self-signed (no domain), imported into ACM
- Port 443 listener: HTTPS, forwards to the target group
- Port 80 listener: fixed response 403 "HTTP traffic blocked - use HTTPS"
 
Test:
- curl -i http://<alb-dns> gives 403
- curl -k -i https://<alb-dns> gives 200 (-k because the cert is self-signed)
