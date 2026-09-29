locals {
  stem = "${var.name_prefix}-${var.name_suffix}"
  names = merge({
    resource_group  = "rg-${local.stem}"
    vnet            = "vnet-${local.stem}"
    apps_subnet     = "snet-${var.name_prefix}-apps-${var.name_suffix}"
    postgres_subnet = "snet-${var.name_prefix}-postgres-${var.name_suffix}"
    logs            = "log-${local.stem}"
    environment     = "cae-${local.stem}"
    app             = "ca-${var.name_prefix}-api-${var.name_suffix}"
    identity        = "id-${var.name_prefix}-acrpull-${var.name_suffix}"
    postgres        = "psql-${local.stem}-${var.unique_suffix}"
    static_web_app  = "swa-${local.stem}"
  }, var.resource_names)
}

resource "azurerm_resource_group" "tripper" {
  name     = local.names.resource_group
  location = var.location
  tags     = var.tags
}

data "azurerm_container_registry" "existing" {
  provider            = azurerm.registry
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

resource "azurerm_user_assigned_identity" "acr_pull" {
  name                = local.names.identity
  resource_group_name = azurerm_resource_group.tripper.name
  location            = azurerm_resource_group.tripper.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  provider                         = azurerm.registry
  scope                            = data.azurerm_container_registry.existing.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.acr_pull.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_log_analytics_workspace" "tripper" {
  name                = local.names.logs
  resource_group_name = azurerm_resource_group.tripper.name
  location            = azurerm_resource_group.tripper.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}
