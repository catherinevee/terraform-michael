/**
 * Infrastructure outputs for integration with other resources
 * Provides essential identifiers and endpoints for dependent systems
 */

output "vpc_id" {
  description = "VPC ID for security group and resource references"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs for application deployment"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs for internet-facing resources"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "Database subnet IDs for RDS and other data services"
  value       = module.vpc.database_subnets
}

output "alb_security_group_id" {
  description = "ALB security group ID for load balancer configuration"
  value       = module.alb_security_group.security_group_id
}

output "app_security_group_id" {
  description = "Application security group ID for EC2 instances"
  value       = module.app_security_group.security_group_id
}

output "db_security_group_id" {
  description = "Database security group ID for RDS instances"
  value       = module.db_security_group.security_group_id
}

output "rds_endpoint" {
  description = "RDS connection endpoint for application configuration"
  value       = module.db.db_instance_endpoint
  sensitive   = true  # Contains hostname that might reveal internal structure
}

output "alb_dns_name" {
  description = "Load balancer DNS name for external access and DNS records"
  value       = module.alb.lb_dns_name
}

output "kms_key_arn" {
  description = "KMS key ARN for additional resource encryption"
  value       = aws_kms_key.main.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for application logging configuration"
  value       = aws_cloudwatch_log_group.main.name
}
