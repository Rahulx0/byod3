terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "example" {
  ami           = "ami-068c0051b15cdb816"  
  instance_type = var.instance_type

  tags = {
    Name = "BYOD3-Instance"
  }
}