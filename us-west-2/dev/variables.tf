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
  default     = "dev"
  
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
  default     = "172.16.0.0/16"
}

variable "azs" {
  description = "Availability zones in us-west-2"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]  # us-west-2 has 3 AZs
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.201.0/24", "172.16.202.0/24", "172.16.203.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"  # Using slightly larger instance type
  
  validation {
    condition     = can(regex("^(t3|t4g|m5|m6i|c5|c6i|r5|r6i)", var.instance_type))
    error_message = "Instance type must be from approved families for cost optimization."
  }
}
