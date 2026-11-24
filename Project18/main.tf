terraform {
  required_version = ">= 1.4"
}

resource "terraform_data" "demo" {
  input = "Shlok Project 18 - applied after PR merge"
}

output "message" {
  value = terraform_data.demo.output
}
