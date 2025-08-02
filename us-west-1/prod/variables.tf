variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "state_kms_key_id" {
  description = "KMS Key ID for state encryption"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project)) && length(var.project) <= 32
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 32 characters."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.20.0.0/16"  # Production CIDR range
}

variable "azs" {
  description = "Availability zones in us-west-1"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1b"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["172.20.1.0/24", "172.20.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["172.20.101.0/24", "172.20.102.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["172.20.201.0/24", "172.20.202.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.large"  # Production-grade instance type
  
  validation {
    condition     = can(regex("^(m5|m6i|c5|c6i|r5|r6i)", var.instance_type))
    error_message = "Instance type must be from approved production families for performance and reliability."
  }
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.m5.xlarge"  # Production-grade RDS instance
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30  # 30 days retention for production
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = true  # Always true for production
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true  # Always true for production
}
