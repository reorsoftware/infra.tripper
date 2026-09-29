output "storage_account_id" {
  value = azurerm_storage_account.state.id
}

output "backend_configuration" {
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    key                  = "tripper.tfstate"
    subscription_id      = var.subscription_id
    tenant_id            = var.tenant_id
    use_azuread_auth     = true
  }
}
