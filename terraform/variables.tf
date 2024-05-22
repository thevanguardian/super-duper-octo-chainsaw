locals {
  app_name = "${var.app_name}-${terraform.workspace}"
}
variable "app_name" {
  type = string
  description = "Identifiable name for the application."
  default = "container-sorcerer"
}
variable "region" {
  type = string
  description = "AWS Region to deploy var.app_name into."
  default = "us-east-2"
}

