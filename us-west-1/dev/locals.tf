/**
 * Local values for resource naming and tagging consistency
 * Generates standardized names following project conventions
 */

locals {
  name_prefix = "${var.project}-${var.environment}-usw1"
  
  # Standard tags applied to all resources for cost tracking and management
  mandatory_tags = {
    Environment  = var.environment
    Project      = var.project
    ManagedBy    = "terraform"
    CostCenter   = "infrastructure"
    BusinessUnit = "technology"
    DataClass    = "internal"
  }
  
  # Consistent resource naming following company conventions
  vpc_name               = "${local.name_prefix}-vpc"
  app_sg_name           = "${local.name_prefix}-app-sg"
  alb_sg_name           = "${local.name_prefix}-alb-sg"
  db_sg_name            = "${local.name_prefix}-db-sg"
  kms_key_name          = "${local.name_prefix}-key"
  secret_name           = "${local.name_prefix}-secret"
  rds_name              = "${local.name_prefix}-rds"
  bastion_name          = "${local.name_prefix}-bastion"
  alb_name              = "${local.name_prefix}-alb"
  log_group_name        = "/aws/${var.project}/${var.environment}"
}
