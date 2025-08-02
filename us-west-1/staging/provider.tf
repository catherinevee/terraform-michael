terraform {
  required_version = "1.13.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-${var.account_id}"
    key            = "environments/staging/us-west-1/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
    kms_key_id     = "arn:aws:kms:us-west-1:${var.account_id}:key/${var.state_kms_key_id}"
  }
}

provider "aws" {
  region = "us-west-1"
  
  default_tags {
    tags = local.mandatory_tags
  }
  
  retry_mode  = "adaptive"
  max_retries = 10
}
