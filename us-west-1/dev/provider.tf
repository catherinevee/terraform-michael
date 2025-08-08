/**
 * Terraform and AWS provider configuration for us-west-1 development
 * Locked versions ensure consistent behavior across team and CI/CD
 */

terraform {
  required_version = "1.13.0"  # Pinned version for team consistency
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"         # Latest stable with required features
    }
  }

  backend "s3" {
    bucket         = "terraform-state-${var.account_id}"
    key            = "environments/dev/us-west-1/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true                    # Encryption at rest
    dynamodb_table = "terraform-state-locks" # Prevent concurrent modifications
    kms_key_id     = "arn:aws:kms:us-west-1:${var.account_id}:key/${var.state_kms_key_id}"
  }
}

provider "aws" {
  region = "us-west-1"
  
  # Apply mandatory tags to all resources for cost allocation
  default_tags {
    tags = local.mandatory_tags
  }
  
  # Adaptive retry helps with API rate limits during large deployments
  retry_mode  = "adaptive"
  max_retries = 10
}
