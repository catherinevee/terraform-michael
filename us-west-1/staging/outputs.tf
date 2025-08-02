output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
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

output "rds_port" {
  description = "The port on which the DB accepts connections"
  value       = module.db.db_instance_port
}

output "rds_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
}

output "rds_multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = module.db.db_instance_multi_az
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.lb_dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the load balancer"
  value       = module.alb.lb_zone_id
}

output "target_group_arns" {
  description = "List of target group ARNs"
  value       = module.alb.target_group_arns
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.arn
}
