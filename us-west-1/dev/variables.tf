/**
 * Variables for us-west-1 development environment
 * Cost-optimized settings with basic security controls
 */

variable "account_id" {
  description = "AWS Account ID for resource ARN construction"
  type        = string
}

variable "state_kms_key_id" {
  description = "KMS Key ID for Terraform state encryption"
  type        = string
}

variable "environment" {
  description = "Environment name affecting resource naming and configuration"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project)) && length(var.project) <= 32
    error_message = "Project name must be lowercase, alphanumeric with hyphens, max 32 chars."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block - must not overlap with other environments"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for us-west-1 region"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1b"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs for application tier"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs for internet-facing resources"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDRs for RDS instances"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type from approved cost-effective families"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^(t3|t4g|m5|m6i|c5|c6i|r5|r6i)", var.instance_type))
    error_message = "Instance type must be from approved families for cost optimization."
  }
}
