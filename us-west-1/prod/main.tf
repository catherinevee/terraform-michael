# VPC Module with production configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway          = var.enable_nat_gateway
  single_nat_gateway         = false
  one_nat_gateway_per_az     = true
  enable_vpn_gateway         = false
  enable_dns_hostnames       = true
  enable_dns_support         = true
  
  # Production-specific network configuration
  enable_network_address_usage_metrics = true
  map_public_ip_on_launch             = false
  
  # Database subnet configuration
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  
  # VPC Flow Logs with extended configuration
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  flow_log_traffic_type                = "ALL"
}

# KMS Key for production encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project} ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region           = true
  
  # Production-specific key policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = local.kms_key_name
  }
}

# Production Security Groups with strict rules
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.alb_sg_name
  description = "Security group for Production ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]  # HTTPS only
  egress_rules        = ["all-all"]
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.app_sg_name
  description = "Security group for production application instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description             = "HTTPS from ALB"
    }
  ]
  egress_rules = ["all-all"]
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.db_sg_name
  description = "Security group for production RDS"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                = "tcp"
      source_security_group_id = module.app_security_group.security_group_id
      description             = "MySQL from application servers"
    }
  ]
}

# Production CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = local.log_group_name
  retention_in_days = 365  # 1 year retention for production
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = local.log_group_name
  }
}

# Production RDS Instance
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.rds_name

  engine               = "mysql"
  engine_version       = "8.0.33"
  family              = "mysql8.0"
  major_engine_version = "8.0"
  instance_class      = var.rds_instance_class

  allocated_storage     = 200
  max_allocated_storage = 1000
  storage_type         = "gp3"
  iops                 = 12000

  db_name  = "production"
  username = "admin"
  port     = 3306

  multi_az               = var.multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = local.maintenance_window
  backup_window      = local.backup_window

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot    = false
  deletion_protection    = var.deletion_protection

  performance_insights_enabled          = true
  performance_insights_retention_period = 731  # 2 years
  create_monitoring_role               = true
  monitoring_interval                  = 10    # Enhanced monitoring

  parameters = local.rds_parameters

  tags = {
    Name = local.rds_name
  }
}

# Production WAF for ALB
resource "aws_wafv2_web_acl" "main" {
  name        = local.waf_name
  description = "Production WAF ACL"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "IPRateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.waf_ip_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "IPRateLimitMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ProductionWAFMetric"
    sampled_requests_enabled  = true
  }
}

# Production Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.alb_name

  load_balancer_type = "application"
  internal           = false  # Internet-facing

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_security_group.security_group_id]

  target_groups = [
    {
      name_prefix          = "prod-"
      backend_protocol     = "HTTPS"
      backend_port         = 443
      target_type         = "instance"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 10
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout            = 5
        protocol           = "HTTPS"
        matcher            = "200"
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
      ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Modern SSL policy
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
    bucket  = "${local.name_prefix}-alb-logs"
    prefix  = "production-alb"
    enabled = true
  }

  tags = {
    Name = local.alb_name
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = module.alb.lb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# CloudWatch Alarms for Production Monitoring
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.rds_name}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = local.cpu_threshold
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions      = []  # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "${local.rds_name}-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1073741824"  # 1GB in bytes
  alarm_description   = "RDS freeable memory is too low"
  alarm_actions      = []  # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.rds_name}-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "53687091200"  # 50GB in bytes
  alarm_description   = "RDS free storage space is too low"
  alarm_actions      = []  # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
}
