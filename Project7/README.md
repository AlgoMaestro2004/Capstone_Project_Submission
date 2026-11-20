# Project 7: CI Validation for Terraform
 
![Terraform CI](https://github.com/AlgoMaestro2004/Capstone_Project_Submission/actions/workflows/terraform-ci.yml/badge.svg)
 
On every push, GitHub Actions runs `terraform fmt -check`,
`terraform init -backend=false` and `terraform validate` on the
Terraform code in this folder.
