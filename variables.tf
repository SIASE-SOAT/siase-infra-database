variable "aws_region" {
  type        = string
  description = "Região AWS."
}

variable "environment" {
  type        = string
  description = "Ambiente lógico."

  validation {
    condition     = contains(["homolog", "production"], var.environment)
    error_message = "environment deve ser homolog ou production."
  }
}

variable "project_name" {
  type    = string
  default = "siase"
}

variable "db_name" {
  type    = string
  default = "siase"
}

variable "db_username" {
  type    = string
  default = "siase_master"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 20
}

variable "slow_query_duration_ms" {
  type    = number
  default = 1000
}

variable "backup_retention_days" {
  type        = number
  description = "Homolog deve usar retenção menor; produção, maior."
}

variable "backup_window" {
  type = string
}

variable "maintenance_window" {
  type = string
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "deletion_protection" {
  type = bool
}

variable "multi_az" {
  type = bool
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
