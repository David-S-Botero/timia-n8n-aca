provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  # Naming convention
  name_prefix        = "${var.client}-${var.app}-${var.environment}"
  resource_group_name = "${var.client}-${var.app}-${var.environment}"
  
  # Common tags
  common_tags = {
    client     = var.client
    app        = var.app
    environment = var.environment
    managed_by = "terraform"
  }
  
  # PostgreSQL configuration
  pg_version         = var.pg_version
  pg_storage_mb      = var.pg_storage_mb
  pg_zone            = "1"
  pg_sku_name        = var.pg_sku_name
  pg_database_name   = "n8n"
  pg_port            = "5432"
  
  # n8n configuration
  n8n_port           = "5678"
  n8n_protocol       = "https"
  n8n_timezone       = "America/Bogota"
  n8n_host           = "timia-n8n-dev.redglacier-1a406574.eastus2.azurecontainerapps.io"
  n8n_webhook_url    = "https://timia-n8n-dev.redglacier-1a406574.eastus2.azurecontainerapps.io"
  n8n_editor_url     = "https://timia-n8n-dev.redglacier-1a406574.eastus2.azurecontainerapps.io"
  
  # Container configuration
  container_cpu      = var.container_cpu
  container_memory   = var.container_memory
  container_image    = var.container_image
  min_replicas       = var.min_replicas
  max_replicas       = var.max_replicas
  
  # SSL configuration
  ssl_reject_unauthorized = "false"
  ssl_mode                = "require"
}

# Crear el Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "n8n_db" {
  name                   = local.name_prefix
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.pg_admin_user
  administrator_password = var.pg_admin_pass
  version                = local.pg_version
  storage_mb             = local.pg_storage_mb
  zone                   = local.pg_zone

  sku_name = local.pg_sku_name

  authentication {
    password_auth_enabled = true
  }

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "n8n_database" {
  name      = local.pg_database_name
  server_id = azurerm_postgresql_flexible_server.n8n_db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = local.name_prefix
  server_id        = azurerm_postgresql_flexible_server.n8n_db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_container_app_environment" "n8n_env" {
  name                = local.name_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_container_app" "n8n_app" {
  name                         = local.name_prefix
  container_app_environment_id = azurerm_container_app_environment.n8n_env.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = "n8n"
      image  = local.container_image
      cpu    = local.container_cpu
      memory = local.container_memory

      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_HOST"
        value = azurerm_postgresql_flexible_server.n8n_db.fqdn
      }
      env {
        name  = "DB_POSTGRESDB_PORT"
        value = local.pg_port
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = local.pg_database_name
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = var.pg_admin_user
      }
      env {
        name  = "DB_POSTGRESDB_PASSWORD"
        value = var.pg_admin_pass
      }
      env {
        name  = "N8N_ENCRYPTION_KEY"
        value = var.n8n_encryption_key
      }
      env {
        name  = "N8N_HOST"
        value = local.n8n_host
      }
      env {
        name  = "N8N_PORT"
        value = local.n8n_port
      }
      env {
        name  = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED"
        value = local.ssl_reject_unauthorized
      }
      env {
        name  = "DB_POSTGRESDB_SSL_MODE"
        value = local.ssl_mode
      }
      env {
        name  = "N8N_PROTOCOL"
        value = local.n8n_protocol
      }
      env {
        name  = "WEBHOOK_URL"
        value = local.n8n_webhook_url
      }
      env {
        name  = "N8N_EDITORBASE_URL"
        value = local.n8n_editor_url
      }
      env {
        name  = "TZ"
        value = local.n8n_timezone
      }
    }

    min_replicas = local.min_replicas
    max_replicas = local.max_replicas
  }

  ingress {
    external_enabled = true
    target_port      = local.n8n_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags
}