/**
 * Development environment infrastructure for us-west-1
 * Cost-optimized configuration with basic monitoring and single-AZ resources
 */

# VPC with public, private, and database subnet tiers
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.environment != "prod"  # Cost optimization for non-prod
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # RDS requires dedicated subnet group
  create_database_subnet_group = true
  
  # VPC Flow Logs for network security monitoring
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}

# Customer-managed KMS key for encryption at rest
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project} ${var.environment}"
  deletion_window_in_days = 7                 # Minimum safe deletion window
  enable_key_rotation     = true              # Annual rotation for security
  
  tags = {
    Name = local.kms_key_name
  }
}

# ALB security group - public internet access
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.alb_sg_name
  description = "Internet-facing ALB access control"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_rules        = ["all-all"]
}

# Application security group - ALB access only
module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.app_sg_name
  description = "Application instances - ALB traffic only"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
    }
  ]
  egress_rules = ["all-all"]
}

# Database security group - application access only
module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.db_sg_name
  description = "RDS MySQL - app tier access only"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                = "tcp"
      source_security_group_id = module.app_security_group.security_group_id
    }
  ]
}

# CloudWatch log group for application and infrastructure logs
resource "aws_cloudwatch_log_group" "main" {
  name              = local.log_group_name
  retention_in_days = 30                    # Shorter retention for dev to control costs
  kms_key_id        = aws_kms_key.main.arn  # Encrypted storage

  tags = {
    Name = local.log_group_name
  }
}

# MySQL RDS instance with basic monitoring for development
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.rds_name

  engine               = "mysql"
  engine_version       = "8.0"
  family              = "mysql8.0"
  major_engine_version = "8.0"
  instance_class      = "db.t3.small"      # Cost-effective for development

  allocated_storage     = 20               # Minimum viable storage
  max_allocated_storage = 100              # Allow growth for testing

  db_name  = "app"
  username = "admin"
  port     = 3306

  multi_az               = false           # Single AZ saves ~50% on RDS costs
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"  # Low-traffic window
  backup_window      = "03:00-06:00"          # After maintenance

  backup_retention_period = 7              # Minimum retention for dev
  skip_final_snapshot    = true            # No final snapshot for dev

  storage_encrypted = true
  kms_key_id       = aws_kms_key.main.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7    # Short retention for dev
  create_monitoring_role               = true
  monitoring_interval                  = 60    # Basic monitoring interval

  # UTF-8 charset for international character support
  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = {
    Name = local.rds_name
  }
}

# Application Load Balancer for HTTP traffic distribution
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.alb_name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "app-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path               = "/health"           # Application must implement health endpoint
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 6
        protocol           = "HTTP"
        matcher            = "200-399"
      }
    }
  ]

  # HTTP-only for development - HTTPS added in staging/prod
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Name = local.alb_name
  }
}
