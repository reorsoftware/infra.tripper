output "resource_group_name" {
  value = azurerm_resource_group.tripper.name
}

output "acr_login_server" {
  value = data.azurerm_container_registry.existing.login_server
}

output "acr_name" {
  value = data.azurerm_container_registry.existing.name
}

output "acr_resource_id" {
  value = data.azurerm_container_registry.existing.id
}

output "container_app_name" {
  value = azurerm_container_app.backend.name
}

output "container_app_environment_name" {
  value = azurerm_container_app_environment.tripper.name
}

output "container_app_url" {
  value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.tripper.fqdn
}

output "postgres_database_name" {
  value = azurerm_postgresql_flexible_server_database.tripper.name
}

output "static_web_app_name" {
  value = azurerm_static_web_app.frontend.name
}

output "static_web_app_hostname" {
  value = azurerm_static_web_app.frontend.default_host_name
}

output "static_web_app_deployment_token" {
  value     = azurerm_static_web_app.frontend.api_key
  sensitive = true
}
