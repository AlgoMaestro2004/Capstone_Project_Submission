terraform {
  required_version = ">= 1.4.0"
}
 
resource "terraform_data" "project12" {
  input = "project12-ci-plan"
}
 
output "message" {
  value = terraform_data.project12.input
}
