variable "aws_region" {
  type        = string
  description = "Região AWS."
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Ambiente fixo."
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
  default     = 1
  description = "Retenção curta para o Learner Lab."
}

variable "backup_window" {
  type    = string
  default = "03:00-03:30"
}

variable "maintenance_window" {
  type    = string
  default = "sun:04:00-sun:04:30"
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
