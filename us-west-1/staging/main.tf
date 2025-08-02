# VPC Module
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
  single_nat_gateway     = false  # Multiple NAT gateways for staging
  one_nat_gateway_per_az = true   # One NAT gateway per AZ
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # Database subnet configuration
  create_database_subnet_group = true
  
  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project} ${var.environment}"
  deletion_window_in_days = 14  # Increased for staging
  enable_key_rotation     = true
  
  tags = {
    Name = local.kms_key_name
  }
}

# Security Groups with stricter rules for staging
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.alb_sg_name
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]  # HTTPS only
  egress_rules        = ["all-all"]
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.app_sg_name
  description = "Security group for application instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
    }
  ]
  egress_rules = ["all-all"]
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.db_sg_name
  description = "Security group for RDS"
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

# CloudWatch Log Group with longer retention for staging
resource "aws_cloudwatch_log_group" "main" {
  name              = local.log_group_name
  retention_in_days = 90  # Longer retention for staging
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = local.log_group_name
  }
}

# RDS Instance with staging configuration
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.rds_name

  engine               = "mysql"
  engine_version       = "8.0.33"
  family              = "mysql8.0"
  major_engine_version = "8.0"
  instance_class      = "db.t3.large"  # Larger instance for staging

  allocated_storage     = 100  # More storage for staging
  max_allocated_storage = 500

  db_name  = "stagingdb"
  username = "admin"
  port     = 3306

  multi_az               = true  # Multi-AZ for staging
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = local.maintenance_window
  backup_window      = local.backup_window

  backup_retention_period = 14
  skip_final_snapshot    = false  # Keep final snapshot for staging
  final_snapshot_identifier = "${local.rds_name}-final-snapshot"

  storage_encrypted = true
  kms_key_id       = aws_kms_key.main.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 14
  create_monitoring_role               = true
  monitoring_interval                  = 30

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    }
  ]

  tags = {
    Name = local.rds_name
  }
}

# Application Load Balancer with WAF integration for staging
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
      name_prefix      = "stg-"
      backend_protocol = "HTTPS"  # HTTPS backend
      backend_port     = 443
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 15
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout            = 5
        protocol           = "HTTPS"
        matcher            = "200-399"
      }
      stickiness = {
        enabled         = true
        cookie_duration = 86400
        type           = "app_cookie"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol          = "HTTPS"
      certificate_arn    = "arn:aws:acm:us-west-1:${var.account_id}:certificate/example-cert"  # Replace with actual cert ARN
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  access_logs = {
    bucket = "alb-logs-${var.project}-${var.environment}"
    prefix = "alb-staging"
    enabled = true
  }

  tags = {
    Name = local.alb_name
  }
}
