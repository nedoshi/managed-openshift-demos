terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    rhcs = {
      version = ">= 1.5.0"
      source  = "terraform-redhat/rhcs"
    }
  }
}

data "aws_caller_identity" "current" {}

provider "rhcs" {
  token        = var.token
  # client_id    = var.client_id
  #client_secret =  var.client_secret
}

provider "aws" {
  region = "us-east-1"
}