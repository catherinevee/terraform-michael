output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = module.alb_security_group.security_group_id
}

output "app_security_group_id" {
  description = "The ID of the application security group"
  value       = module.app_security_group.security_group_id
}

output "db_security_group_id" {
  description = "The ID of the database security group"
  value       = module.db_security_group.security_group_id
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.lb_dns_name
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}
