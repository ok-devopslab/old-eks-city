data "aws_caller_identity" "current" {}

resource "random_password" "password" {
  length      = 25
  upper       = true
  special     = false
  min_numeric = 5
}

resource "aws_rds_cluster_parameter_group" "default" {
  name        = "aurora-${var.environment}-cluster"
  family      = "aurora-mysql5.7"
  description = "${var.environment}-aurora"

  parameter {
    name         = "max_connections"
    value        = "10000"
    apply_method = "immediate"
  }

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "aurora_parallel_query"
    value        = "ON"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "aurora-${var.environment}-instance"
  family = "aurora-mysql5.7"

  parameter {
    name         = "max_connections"
    value        = "1000"
    apply_method = "immediate"
  }

  parameter {
    name         = "aurora_parallel_query"
    value        = "ON"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}
#
#module "mysql" {
#  depends_on                      = [aws_rds_cluster_parameter_group.default]
#  source                          = "registry.terraform.io/terraform-aws-modules/rds-aurora/aws"
#  version                         = "5.3.0"
#  name                            = "${var.environment}-mysql"
#  engine                          = "aurora-mysql"
#  engine_version                  = "5.7.mysql_aurora.2.10.2"
#  instance_type                   = var.environment == "dev" ? "db.t4g.medium" : "db.t4g.medium"
#  vpc_id                          = data.terraform_remote_state.vpc.outputs.vpc_id
#  create_random_password          = false
#  password                        = random_password.password.result
#  subnets                         = data.terraform_remote_state.vpc.outputs.db_subnets
#  replica_count                   = var.environment == "dev" ? 1 : 3
#  allowed_cidr_blocks             = concat(data.terraform_remote_state.vpc.outputs.private_subnets_cidr)
#  deletion_protection             = var.environment == "dev" ? false : true
#  backup_retention_period         = var.environment == "dev" ? 7 : 30
#  preferred_backup_window         = "02:00-03:00"
#  publicly_accessible             = false
#  skip_final_snapshot             = false
#  copy_tags_to_snapshot           = true
#  database_name                   = var.environment == "prod-dr" ? "prod" : var.environment
#  storage_encrypted               = false
#  auto_minor_version_upgrade      = true
#  monitoring_interval             = var.environment == "dev" ? 10 : 5
#  replica_scale_enabled           = false
#  replica_scale_min               = 1
#  replica_scale_max               = 5
#  replica_scale_cpu               = var.environment == "dev" ? 70 : 50
#  replica_scale_connections       = 500
#  replica_scale_out_cooldown      = 60
#  replica_scale_in_cooldown       = 300
#  apply_immediately               = var.environment == "dev" ? true : false
#  db_parameter_group_name         = aws_db_parameter_group.default.name
#  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name
#  performance_insights_enabled    = true
#  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
#  tags = {
#    Environment = "${var.environment}-mysql"
#    CreateBy    = "Terraform"
#  }
#}



resource "aws_rds_global_cluster" "aws_rds_global_cluster" {
  count                     = var.environment == "prod" ? 1 : 0
  global_cluster_identifier = "${var.environment}-mysql-global"
  engine                    = "aurora-mysql"
  engine_version            = "5.7.mysql_aurora.2.10.2"
  database_name             = var.environment
  storage_encrypted         = true
  deletion_protection       = false
}

module "mysql-us-east-1" {
  count          = var.environment == "prod" ? 1 : 0
  source         = "registry.terraform.io/terraform-aws-modules/rds-aurora/aws"
  version        = "7.5.1"
  name           = "${var.environment}-mysql-global"
  engine         = aws_rds_global_cluster.aws_rds_global_cluster[0].engine
  engine_version = aws_rds_global_cluster.aws_rds_global_cluster[0].engine_version
  instance_class = "db.r5.large"
  instances = {
    1 = {
      instance_class = "db.r5.large"
    }
    2 = {
      instance_class = "db.r5.large"
    }
  }
  create_random_password          = false
  vpc_id                          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets                         = data.terraform_remote_state.vpc.outputs.db_subnets
  allowed_cidr_blocks             = concat(data.terraform_remote_state.vpc.outputs.private_subnets_cidr)
  database_name                   = aws_rds_global_cluster.aws_rds_global_cluster[0].database_name
  master_username                 = "root"
  master_password                 = random_password.password.result
  is_primary_cluster              = true
  global_cluster_identifier       = aws_rds_global_cluster.aws_rds_global_cluster[0].global_cluster_identifier
  enable_global_write_forwarding  = true
  storage_encrypted               = true
  apply_immediately               = true
  monitoring_interval             = 10
  kms_key_id                      = aws_kms_key.primary.arn
  db_parameter_group_name         = aws_db_parameter_group.default.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  tags = {
    Environment = "${var.environment}-mysql"
    CreateBy    = "Terraform"
  }
}



resource "aws_rds_cluster_parameter_group" "default_dr" {
  count       = var.environment == "prod" ? 1 : 0
  provider    = aws.secondary
  name        = "aurora-${var.environment}-cluster"
  family      = "aurora-mysql5.7"
  description = "${var.environment}-aurora"

  parameter {
    name         = "max_connections"
    value        = "10000"
    apply_method = "immediate"
  }

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "aurora_parallel_query"
    value        = "ON"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "default_dr" {
  count    = var.environment == "prod" ? 1 : 0
  provider = aws.secondary
  name     = "aurora-${var.environment}-instance"
  family   = "aurora-mysql5.7"

  parameter {
    name         = "max_connections"
    value        = "1000"
    apply_method = "immediate"
  }

  parameter {
    name         = "aurora_parallel_query"
    value        = "ON"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}


module "mysql-us-west-2" {
  providers      = { aws = aws.secondary }
  count          = var.environment == "prod" ? 1 : 0
  source         = "registry.terraform.io/terraform-aws-modules/rds-aurora/aws"
  version        = "7.5.1"
  name           = "${var.environment}-mysql-global"
  engine         = aws_rds_global_cluster.aws_rds_global_cluster[0].engine
  engine_version = aws_rds_global_cluster.aws_rds_global_cluster[0].engine_version
  instance_class = "db.r5.large"
  instances = {
    1 = {
      instance_class = "db.r5.large"
    }
    2 = {
      instance_class = "db.r5.large"
    }
  }
  create_random_password          = false
  vpc_id                          = data.terraform_remote_state.vpc-dr.outputs.vpc_id
  subnets                         = data.terraform_remote_state.vpc-dr.outputs.db_subnets
  allowed_cidr_blocks             = concat(data.terraform_remote_state.vpc-dr.outputs.private_subnets_cidr)
  database_name                   = aws_rds_global_cluster.aws_rds_global_cluster[0].database_name
  is_primary_cluster              = false
  global_cluster_identifier       = aws_rds_global_cluster.aws_rds_global_cluster[0].global_cluster_identifier
  master_username                 = "root"
  master_password                 = random_password.password.result
  enable_global_write_forwarding  = true
  storage_encrypted               = true
  apply_immediately               = true
  monitoring_interval             = 10
  kms_key_id                      = aws_kms_key.secondary.arn
  db_parameter_group_name         = aws_db_parameter_group.default_dr[0].name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default_dr[0].name
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  tags = {
    Environment = "${var.environment}-mysql"
    CreateBy    = "Terraform"
  }
}


data "aws_iam_policy_document" "rds" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn,
      ]
    }
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_key" "primary" {
  policy = data.aws_iam_policy_document.rds.json
}

resource "aws_kms_key" "secondary" {
  provider = aws.secondary
  policy   = data.aws_iam_policy_document.rds.json
}
