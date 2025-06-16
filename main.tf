provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_postgresql_flexible_server" "n8n_db" {
  name                   = var.pg_server_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  administrator_login    = var.pg_admin_user
  administrator_password = var.pg_admin_pass
  version                = "14"
  storage_mb             = 32768
  zone                   = "1"

  sku_name = "B_Standard_B1ms"

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "n8n_database" {
  name      = "n8n"
  server_id = azurerm_postgresql_flexible_server.n8n_db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.n8n_db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_container_app_environment" "n8n_env" {
  name                = "n8n-env"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_container_app" "n8n_app" {
  name                         = "n8n-app"
  container_app_environment_id = azurerm_container_app_environment.n8n_env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "n8n"
      image  = "n8nio/n8n:latest"
      cpu    = 0.5
      memory = "1.0Gi"

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
        value = "5432"
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = "n8n"
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
        value = var.n8n_host
      }
      env {
        name  = "N8N_PORT"
        value = var.n8n_port
      }
      env {
        name  = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED"
        value = "false"
      }
      env {
        name  = "DB_POSTGRESDB_SSL_MODE"
        value = "require"
      }
      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }
      env {
        name  = "WEBHOOK_URL"
        value = "https://${var.n8n_host}"
      }
      env {
        name  = "N8N_EDITORBASE_URL"
        value = "https://${var.n8n_host}"
      }
      env {
        name  = "TZ"
        value = "America/Bogota"
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = true
    target_port      = 5678

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}