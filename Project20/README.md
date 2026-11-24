# Project 20: Load Balanced App Deployment
 
Goal: improve scale and performance.
 
- Own VPC shlok-p20-vpc (10.99.0.0/16) with 2 public subnets in 2 regular availability zones
- 2 EC2 instances (Amazon Linux 2023, t3.micro) running Nginx, each page shows its server number
- Application Load Balancer shlok-p20-alb with an HTTP listener on port 80
- Target group shlok-p20-tg with a health check on / (interval 10s, 2 healthy, 2 unhealthy)
- Web security group allows port 80 only from the ALB security group
 
Result: describe-target-health shows both targets healthy, and repeated curl requests alternate between Server 1 and Server 2.
