terraform {
  # Require a recent Terraform CLI (pinned to latest stable series discovered)
  required_version = ">= 1.14.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Pinned to the latest provider version discovered: 6.28.0
      version = "= 6.28.0"
    }
  }
}

provider "aws" {
  region = var.region
}
