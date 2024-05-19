terraform {
  backend "remote" {
    organization = "thevanguardian"
    workspaces {
      prefix = "super-duper-octo-chainsaw-" # just to make sure it's absolutely unique. Local executions remove this prefix, while HCP uses it.
    }
  }
}
provider "aws" {
  default_tags {
    tags = {
      environment = terraform.workspace
      app = var.app_name
      github_repo = "git@github.com:thevanguardian/super-duper-octo-chainsaw.git"
    }
  }
  region = var.region
}