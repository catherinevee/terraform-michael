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

output "vpc_flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the VPC Flow Log destination"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "security_groups" {
  description = "Map of security group IDs"
  value = {
    alb = module.alb_security_group.security_group_id
    app = module.app_security_group.security_group_id
    db  = module.db_security_group.security_group_id
  }
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "rds_details" {
  description = "Map of RDS instance details"
  value = {
    id              = module.db.db_instance_id
    arn             = module.db.db_instance_arn
    status          = module.db.db_instance_status
    master_username = module.db.db_instance_username
    port            = module.db.db_instance_port
    multi_az        = module.db.db_instance_multi_az
    engine_version  = module.db.db_instance_engine_version
  }
}

output "alb_details" {
  description = "Map of ALB details"
  value = {
    dns_name = module.alb.lb_dns_name
    zone_id  = module.alb.lb_zone_id
    arn      = module.alb.lb_arn
    id       = module.alb.lb_id
  }
}

output "target_groups" {
  description = "Map of target group details"
  value = {
    arns  = module.alb.target_group_arns
    names = module.alb.target_group_names
  }
}

output "waf_details" {
  description = "Map of WAF details"
  value = {
    id   = aws_wafv2_web_acl.main.id
    arn  = aws_wafv2_web_acl.main.arn
    name = aws_wafv2_web_acl.main.name
  }
}

output "kms_key_details" {
  description = "Map of KMS key details"
  value = {
    id   = aws_kms_key.main.id
    arn  = aws_kms_key.main.arn
    alias = aws_kms_key.main.key_id
  }
}

output "cloudwatch_details" {
  description = "Map of CloudWatch resources"
  value = {
    log_group = {
      name = aws_cloudwatch_log_group.main.name
      arn  = aws_cloudwatch_log_group.main.arn
    }
    alarms = {
      rds_cpu     = aws_cloudwatch_metric_alarm.rds_cpu.arn
      rds_memory  = aws_cloudwatch_metric_alarm.rds_memory.arn
      rds_storage = aws_cloudwatch_metric_alarm.rds_storage.arn
    }
  }
}

output "monitoring_endpoints" {
  description = "Map of monitoring endpoints"
  value = {
    cloudwatch = "https://console.aws.amazon.com/cloudwatch/home?region=us-west-1#dashboards:name=${local.name_prefix}"
    rds        = "https://console.aws.amazon.com/rds/home?region=us-west-1#database:id=${module.db.db_instance_id}"
    waf        = "https://console.aws.amazon.com/wafv2/homev2/web-acl/${aws_wafv2_web_acl.main.id}/overview?region=us-west-1"
  }
}
