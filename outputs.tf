output "db_endpoint" {
  value       = aws_db_instance.rds.address
  description = "Endpoint privado do RDS."
}

output "db_name" {
  value = var.db_name
}

output "db_secret_arn" {
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
  description = "ARN do segredo gerenciado pelo RDS."
}

output "db_client_sg_id" {
  value       = aws_security_group.db_clients.id
  description = "SG compartilhado dos clientes do banco."
}
