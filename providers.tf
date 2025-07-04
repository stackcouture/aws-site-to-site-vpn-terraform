terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-tfm-state-bucket-2025"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  # Configuration options
  region  = "ap-south-1"
  alias   = "mum"
}

provider "aws" {
  alias   = "irl"
  region  = "eu-west-1"
}