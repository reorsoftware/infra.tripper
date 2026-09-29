resource "azurerm_virtual_network" "tripper" {
  name                = local.names.vnet
  resource_group_name = azurerm_resource_group.tripper.name
  location            = azurerm_resource_group.tripper.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "apps" {
  name                 = local.names.apps_subnet
  resource_group_name  = azurerm_resource_group.tripper.name
  virtual_network_name = azurerm_virtual_network.tripper.name
  address_prefixes     = var.apps_subnet_prefixes

  delegation {
    name = "container-apps"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = local.names.postgres_subnet
  resource_group_name  = azurerm_resource_group.tripper.name
  virtual_network_name = azurerm_virtual_network.tripper.name
  address_prefixes     = var.postgres_subnet_prefixes

  delegation {
    name = "postgres-flexible-server"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${local.names.postgres}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.tripper.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                 = "postgres-tripper"
  private_dns_zone_id  = azurerm_private_dns_zone.postgres.id
  virtual_network_id   = azurerm_virtual_network.tripper.id
  registration_enabled = false
  tags                 = var.tags
}
