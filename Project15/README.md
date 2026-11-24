# Project 15 - Automate Server Config with Ansible
 
Goal: remote configuration automation.
 
- Controller: Ubuntu VM with Ansible 2.16.3
- Remote target: Amazon Linux 2023 EC2 built with Terraform (main.tf)
- Port 22 is blocked from the controller, so sshd on the target listens on port 443 (set in user_data)
- inventory.ini points Ansible at the target (port 443, key login)
- install_nginx.yml installs Nginx, starts and enables it, and deploys a custom page
 
Result: PLAY RECAP ok=4 changed=3 unreachable=0 failed=0. The page was fetched with curl and Nginx showed active (running) on the remote server.
 
All AWS resources were destroyed afterwards with terraform destroy.
