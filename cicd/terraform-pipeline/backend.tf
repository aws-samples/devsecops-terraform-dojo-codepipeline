terraform {
  required_version = "= 1.0.4"
  backend "s3" {
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.74.1"
    }
  }
}
