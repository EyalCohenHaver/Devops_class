terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

#setting the provider
provider "aws" {
  region = "us-east-1"
}