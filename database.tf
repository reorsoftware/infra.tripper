resource "azurerm_postgresql_flexible_server" "tripper" {
  name                          = local.names.postgres
  resource_group_name           = azurerm_resource_group.tripper.name
  location                      = azurerm_resource_group.tripper.location
  version                       = var.postgres_version
  administrator_login           = var.postgres_admin_username
  administrator_password        = var.postgres_admin_password
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  backup_retention_days         = var.postgres_backup_retention_days
  geo_redundant_backup_enabled  = false
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  tags                          = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.tripper.id
  value     = "POSTGIS"
}

resource "azurerm_postgresql_flexible_server_database" "tripper" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.tripper.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
