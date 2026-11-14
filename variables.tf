variable "databases" {
  description = "Um RDS PostgreSQL dedicado por microsservico"
  type = map(object({
    db_name  = string
    username = string
  }))

  default = {
    os = {
      db_name  = "siase_os_db"
      username = "siase_os_user"
    }
    billing = {
      db_name  = "siase_billing_db"
      username = "siase_billing_user"
    }
    execution = {
      db_name  = "siase_exec_db"
      username = "siase_exec_user"
    }
  }
}
