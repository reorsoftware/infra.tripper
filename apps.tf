resource "azurerm_container_app_environment" "tripper" {
  name                       = local.names.environment
  resource_group_name        = azurerm_resource_group.tripper.name
  location                   = azurerm_resource_group.tripper.location
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.tripper.id
  infrastructure_subnet_id   = azurerm_subnet.apps.id
  tags                       = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "backend" {
  name                         = local.names.app
  resource_group_name          = azurerm_resource_group.tripper.name
  container_app_environment_id = azurerm_container_app_environment.tripper.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_pull.id]
  }

  registry {
    server   = data.azurerm_container_registry.existing.login_server
    identity = azurerm_user_assigned_identity.acr_pull.id
  }

  secret {
    name  = "database-connection-string"
    value = var.database_connection_string
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.container_port
    transport                  = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.container_min_replicas
    max_replicas = var.container_max_replicas
    container {
      name   = "backend"
      image  = var.bootstrap_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name        = "Database__ConnectionString"
        secret_name = "database-connection-string"
      }

      env {
        name  = "ASPNETCORE_HTTP_PORTS"
        value = tostring(var.container_port)
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}

resource "azurerm_static_web_app" "frontend" {
  name                = local.names.static_web_app
  resource_group_name = azurerm_resource_group.tripper.name
  location            = var.static_web_app_location
  sku_tier            = var.static_web_app_sku
  sku_size            = var.static_web_app_sku
  tags                = var.tags
}
