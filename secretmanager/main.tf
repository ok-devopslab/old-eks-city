resource "aws_secretsmanager_secret" "application" {
  count                   = var.environment != "prod-dr" ? 1 : 0
  name                    = "/${var.org_name}/${var.environment}"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "application" {
  count         = var.environment != "prod-dr" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.application[0].id
  secret_string = <<EOF
   {
    "DB_URL": "jdbc:mysql://${data.terraform_remote_state.rds.outputs.mysql_rds_cluster_endpoint_us-east-1}/${data.terraform_remote_state.rds.outputs.mysql_rds_database_name_us-east-1}?autoReconnect=true&useSSL=false",
    "DB_USER": "${data.terraform_remote_state.rds.outputs.mysql_rds_user_name_us-east-1}",
    "DB_PASSWORD": "${data.terraform_remote_state.rds.outputs.mysql_rds_password_us-east-1}",
    "DB_URL_DR": "jdbc:mysql://${data.terraform_remote_state.rds.outputs.mysql_rds_cluster_endpoint_us-west-2}/${data.terraform_remote_state.rds.outputs.mysql_rds_database_name_us-west-2}?autoReconnect=true&useSSL=false",
    "DB_USER_DR": "${data.terraform_remote_state.rds.outputs.mysql_rds_user_name_us-west-2}",
    "DB_PASSWORD_DR": "${data.terraform_remote_state.rds.outputs.mysql_rds_password_us-east-1}"
   }
EOF
}
