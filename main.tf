terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1d0"  # Amazon Linux 2 AMI for us-west-2
  instance_type = var.instance_type

  tags = {
    Name = "BYOD3-Example-Instance"
  }
}