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
  single_nat_gateway     = var.environment != "prod"
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # Database subnet configuration
  create_database_subnet_group = true
  
  # VPC Flow Logs with extended configuration
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  flow_log_traffic_type                = "ALL"  # Capture all traffic
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project} ${var.environment}"
  deletion_window_in_days = 10  # Increased from 7
  enable_key_rotation     = true
  multi_region           = true  # Made it multi-region capable
  
  tags = {
    Name = local.kms_key_name
  }
}

# Security Groups
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.alb_sg_name
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
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
      from_port                = 80
      to_port                  = 80
      protocol                = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
    },
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

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = local.log_group_name
  retention_in_days = 60  # Increased from 30
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = local.log_group_name
  }
}

# RDS Instance
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.rds_name

  engine               = "mysql"
  engine_version       = "8.0.33"  # Specified exact version
  family              = "mysql8.0"
  major_engine_version = "8.0"
  instance_class      = "db.t3.medium"  # Upgraded from small

  allocated_storage     = 50  # Increased from 20
  max_allocated_storage = 200 # Increased from 100

  db_name  = "appdb"  # Changed from app
  username = "admin"
  port     = 3306

  multi_az               = true  # Changed to true for better availability
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 14  # Increased from 7
  skip_final_snapshot    = true

  storage_encrypted = true
  kms_key_id       = aws_kms_key.main.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 14  # Increased from 7
  create_monitoring_role               = true
  monitoring_interval                  = 30   # Decreased from 60 for more frequent monitoring

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
    }
  ]

  tags = {
    Name = local.rds_name
  }
}

# Application Load Balancer
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
        interval            = 15  # Decreased from 30
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 2   # Decreased from 3
        unhealthy_threshold = 2   # Decreased from 3
        timeout            = 5    # Decreased from 6
        protocol           = "HTTP"
        matcher            = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  access_logs = {
    bucket = "alb-logs-${var.project}-${var.environment}"
    prefix = "alb"
    enabled = true
  }

  tags = {
    Name = local.alb_name
  }
}
