locals {
  name_prefix = "${var.project}-${var.environment}-usw1"
  
  mandatory_tags = {
    Environment     = var.environment
    Project         = var.project
    ManagedBy       = "terraform"
    CostCenter      = "production"
    BusinessUnit    = "technology"
    DataClass       = "confidential"
    Criticality    = "high"
    Compliance     = "pci-dss,soc2"
    BackupSchedule = "hourly"
    Region         = "us-west-1"
  }
  
  # Resource naming patterns with production prefix
  vpc_name               = "${local.name_prefix}-vpc"
  app_sg_name           = "${local.name_prefix}-app-sg"
  alb_sg_name           = "${local.name_prefix}-alb-sg"
  db_sg_name            = "${local.name_prefix}-db-sg"
  kms_key_name          = "${local.name_prefix}-key"
  secret_name           = "${local.name_prefix}-secret"
  rds_name              = "${local.name_prefix}-rds"
  bastion_name          = "${local.name_prefix}-bastion"
  alb_name              = "${local.name_prefix}-alb"
  log_group_name        = "/aws/${var.project}/${var.environment}/prod"
  waf_name              = "${local.name_prefix}-waf"
  
  # Production-specific backup and maintenance windows
  backup_window         = "00:00-03:00"
  maintenance_window    = "Tue:03:00-Tue:06:00"
  
  # Production-specific monitoring thresholds
  cpu_threshold         = "75"
  memory_threshold      = "75"
  disk_threshold        = "80"
  
  # Production WAF rules
  waf_ip_rate_limit    = "2000"  # Requests per 5 minutes per IP
  waf_block_countries  = ["CN", "RU", "IR", "KP"]  # Example countries to block
  
  # RDS parameter group settings
  rds_parameters = [
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
      value = "5000"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "1"
    },
    {
      name  = "max_allowed_packet"
      value = "1073741824"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    }
  ]
}
