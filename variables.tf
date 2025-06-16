variable "resource_group_name" {
  default = "timia-learning-dev_group"
}

variable "location" {
  default = "eastus2"
}

variable "pg_server_name" {
  default = "n8npgflex"
}

variable "pg_admin_user" {
  default = "n8nadmin"
}

variable "subscription_id" {}

variable "pg_admin_pass" {}

variable "n8n_encryption_key" {}

variable "n8n_host" {}

variable "n8n_port" {}