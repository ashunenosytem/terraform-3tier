terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  alias  = "frontend"
  region = "us-east-1a"
}

provider "aws" {
  alias  = "backend"
  region = "ap-south-1"
}
