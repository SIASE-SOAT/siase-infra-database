output "service_db_endpoints" {
  value       = { for k, db in aws_db_instance.rds : k => db.address }
  description = "Endpoints privados dos bancos por microsserviço."
}

output "service_db_names" {
  value = { for k, db in var.databases : k => db.db_name }
}

output "service_db_secret_arns" {
  value       = { for k, db in aws_db_instance.rds : k => db.master_user_secret[0].secret_arn }
  description = "ARNs dos secrets gerenciados pelo RDS, por microsserviço."
}

output "db_client_sg_id" {
  value       = aws_security_group.db_clients.id
  description = "SG compartilhado dos clientes do banco."
}
