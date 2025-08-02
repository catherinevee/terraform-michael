locals {
  name_prefix = "${var.project}-${var.environment}-usw1"
  
  mandatory_tags = {
    Environment  = var.environment
    Project      = var.project
    ManagedBy    = "terraform"
    CostCenter   = "infrastructure"
    BusinessUnit = "technology"
    DataClass    = "internal"
    Stage        = "pre-production"  # Added staging-specific tag
    Backup       = "daily"           # Added backup tag
  }
  
  # Resource naming patterns with staging prefix
  vpc_name               = "${local.name_prefix}-vpc"
  app_sg_name           = "${local.name_prefix}-app-sg"
  alb_sg_name           = "${local.name_prefix}-alb-sg"
  db_sg_name            = "${local.name_prefix}-db-sg"
  kms_key_name          = "${local.name_prefix}-key"
  secret_name           = "${local.name_prefix}-secret"
  rds_name              = "${local.name_prefix}-rds"
  bastion_name          = "${local.name_prefix}-bastion"
  alb_name              = "${local.name_prefix}-alb"
  log_group_name        = "/aws/${var.project}/${var.environment}/staging"
  
  # Staging-specific backup windows
  backup_window         = "02:00-05:00"
  maintenance_window    = "Sun:05:00-Sun:08:00"
}
