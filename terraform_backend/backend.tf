terraform {
  required_version = "= 1.0.4"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.74.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "= 2.1.0"
    }
  }
}
