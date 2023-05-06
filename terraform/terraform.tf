terraform {

  backend "s3" {
    bucket = "juice-shop-terraform-state"
    key    = "terraform"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

}

provider "aws" {
  region = "us-east-1"
}
