# Project 21 - CloudWatch Monitoring Dashboard
 
Goal: visualize performance. Built with Terraform in ap-south-1.
 
Resources (8): own VPC 10.55.0.0/16, subnet, internet gateway, route table + association, security group (port 80), EC2 shlok-p21-web (Nginx, detailed monitoring), CloudWatch dashboard Shlok-Project21-Monitoring-Dashboard.
 
Widgets (4): EC2 CPU Utilization, Network In, Network Out, EC2 Status Checks.
 
Proof:
- project21-dashboard.json: the dashboard read back with aws cloudwatch get-dashboard.
- capstone_21_1.png and capstone_21_2.png: CPU and Network In graphs made with aws cloudwatch get-metric-widget-image.
 
Note: my web console login (a different user from my CLI user) is blocked by an organization service control policy (explicit deny on cloudwatch:ListDashboards and GetDashboard), so the console page could not be opened. The proof comes from the CLI user instead.
