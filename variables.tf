variable "client" {
  description = "Nombre del cliente"
  default     = "timia"
}

variable "app" {
  description = "Nombre de la aplicación"
  default     = "n8n"
}

variable "environment" {
  description = "Ambiente de despliegue"
  default     = "dev"
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos"
  default     = "eastus2"
}

variable "pg_admin_user" {
  description = "Usuario administrador de PostgreSQL"
  default     = "n8nadmin"
}

variable "pg_admin_pass" {
  description = "Contraseña del administrador de PostgreSQL"
  sensitive   = true
}

variable "n8n_encryption_key" {
  description = "Clave de encriptación para n8n"
  sensitive   = true
}

variable "subscription_id" {}

variable "pg_version" {}

variable "pg_storage_mb" {}

variable "pg_sku_name" {}

variable "container_cpu" {}

variable "container_memory" {}

variable "container_image" {}

variable "min_replicas" {}

variable "max_replicas" {}
