#output "mysql_rds_cluster_endpoint" {
#  value = module.mysql.rds_cluster_endpoint
#}
#
#output "mysql_rds_user_name" {
#  value     = module.mysql.rds_cluster_master_username
#  sensitive = true
#}
#
#output "mysql_rds_password" {
#  value     = module.mysql.rds_cluster_master_password
#  sensitive = true
#}
#
#output "mysql_rds_database_name" {
#  value = module.mysql.rds_cluster_database_name
#}
#
#output "mysql_rds_port" {
#  value = module.mysql.rds_cluster_port
#}

output "mysql_rds_cluster_endpoint_us-east-1" {
  value = module.mysql-us-east-1[0].cluster_endpoint
}

output "mysql_rds_user_name_us-east-1" {
  value     = module.mysql-us-east-1[0].cluster_master_username
  sensitive = true
}

output "mysql_rds_password_us-east-1" {
  value     = module.mysql-us-east-1[0].cluster_master_password
  sensitive = true
}

output "mysql_rds_database_name_us-east-1" {
  value = module.mysql-us-east-1[0].cluster_database_name
}

output "mysql_rds_port_us-east-1" {
  value = module.mysql-us-east-1[0].cluster_port
}

output "mysql_rds_cluster_endpoint_us-west-2" {
  value = module.mysql-us-west-2[0].cluster_endpoint
}

output "mysql_rds_user_name_us-west-2" {
  value     = module.mysql-us-west-2[0].cluster_master_username
  sensitive = true
}

output "mysql_rds_password_us-west-2" {
  value     = module.mysql-us-west-2[0].cluster_master_password
  sensitive = true
}

output "mysql_rds_database_name_us-west-2" {
  value = module.mysql-us-west-2[0].cluster_database_name
}

output "mysql_rds_port_us-west-2" {
  value = module.mysql-us-west-2[0].cluster_port
}


