terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.14"
    }
  }

  required_version = ">= 0.13.6"
}

provider "aws" {
  region  = "eu-west-1"
}
