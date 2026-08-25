locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  private_subnet_ids = jsondecode(data.aws_ssm_parameter.private_subnet_ids.value)
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for SIASE RDS ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_security_group" "db_clients" {
  name        = "${local.name}-db-clients"
  description = "SG compartilhado dos clientes autorizados do PostgreSQL"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  tags        = local.common_tags
}

resource "aws_security_group_rule" "db_clients_from_eks_nodes" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_clients.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = data.aws_ssm_parameter.eks_node_sg_id.value
  description              = "Clientes Kubernetes do cluster SIASE"
}

resource "aws_security_group_rule" "db_clients_egress" {
  type              = "egress"
  security_group_id = aws_security_group.db_clients.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Egress necessario para conexoes dos clientes"
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Security Group do PostgreSQL gerenciado"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  tags        = local.common_tags
}

resource "aws_security_group_rule" "rds_from_db_clients" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_clients.id
  description              = "Somente clientes do banco"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  security_group_id = aws_security_group.rds.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_subnet_group" "rds" {
  name       = "${local.name}-subnets"
  subnet_ids = local.private_subnet_ids
  tags       = local.common_tags
}

resource "aws_db_parameter_group" "rds" {
  name   = "${local.name}-postgres16"
  family = "postgres16"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = tostring(var.slow_query_duration_ms)
  }

  tags = local.common_tags
}

resource "aws_db_instance" "rds" {
  identifier = local.name

  engine                = "postgres"
  engine_version        = "16"
  instance_class        = var.db_instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.rds.name

  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  multi_az              = var.multi_az
  deletion_protection   = var.deletion_protection
  skip_final_snapshot   = var.skip_final_snapshot
  copy_tags_to_snapshot = true
  publicly_accessible   = false

  performance_insights_enabled    = false
  monitoring_interval             = 0
  enabled_cloudwatch_logs_exports = ["postgresql"]
  manage_master_user_password     = true
  master_user_secret_kms_key_id   = aws_kms_key.rds.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/siase/production/db-endpoint"
  type  = "String"
  value = aws_db_instance.rds.address
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/siase/production/db-name"
  type  = "String"
  value = var.db_name
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "db_secret_arn" {
  name  = "/siase/production/db-secret-arn"
  type  = "String"
  value = aws_db_instance.rds.master_user_secret[0].secret_arn
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "db_client_sg_id" {
  name  = "/siase/production/db-client-sg-id"
  type  = "String"
  value = aws_security_group.db_clients.id
  tags  = local.common_tags
}
