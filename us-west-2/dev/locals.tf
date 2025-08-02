locals {
  name_prefix = "${var.project}-${var.environment}-usw2"  # Changed to usw2
  
  mandatory_tags = {
    Environment  = var.environment
    Project      = var.project
    ManagedBy    = "terraform"
    CostCenter   = "infrastructure"
    BusinessUnit = "technology"
    DataClass    = "internal"
    Region       = "us-west-2"  # Added region tag
  }
  
  # Resource naming patterns
  vpc_name               = "${local.name_prefix}-vpc"
  app_sg_name           = "${local.name_prefix}-app-sg"
  alb_sg_name           = "${local.name_prefix}-alb-sg"
  db_sg_name            = "${local.name_prefix}-db-sg"
  kms_key_name          = "${local.name_prefix}-key"
  secret_name           = "${local.name_prefix}-secret"
  rds_name              = "${local.name_prefix}-rds"
  bastion_name          = "${local.name_prefix}-bastion"
  alb_name              = "${local.name_prefix}-alb"
  log_group_name        = "/aws/${var.project}/${var.environment}/usw2"  # Added region suffix
}
