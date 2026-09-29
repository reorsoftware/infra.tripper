# Mocked contract tests: no Azure credentials, resources or state backend required.
mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.Network/virtualNetworks/vnet-tripper-uks" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.Network/virtualNetworks/vnet-tripper-uks/subnets/mock-subnet" }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = { id = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.Network/privateDnsZones/tripper.private.postgres.database.azure.com" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-tripper-acrpull-uks"
      principal_id = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = { id = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.OperationalInsights/workspaces/log-tripper-uks" }
  }
  mock_resource "azurerm_container_app_environment" {
    defaults = { id = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.App/managedEnvironments/cae-tripper-uks" }
  }
  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id   = "/subscriptions/6ab40698-3a04-40ef-aa51-2216ec149195/resourceGroups/rg-tripper-uks/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-tripper-uks-6ab40698"
      fqdn = "psql-tripper-uks-6ab40698.postgres.database.azure.com"
    }
  }
}

mock_provider "azurerm" {
  alias = "registry"
  mock_data "azurerm_container_registry" {
    defaults = {
      id           = "/subscriptions/b787b673-6b27-48a9-93fd-c38f53934a10/resourceGroups/rg-identity-01/providers/Microsoft.ContainerRegistry/registries/crreoridentityprod"
      login_server = "crreoridentityprod.azurecr.io"
    }
  }
}

variables {
  subscription_id            = "6ab40698-3a04-40ef-aa51-2216ec149195"
  tenant_id                  = "e9c31ad7-4805-4f03-82eb-4c2b1fee07b8"
  acr_subscription_id        = "b787b673-6b27-48a9-93fd-c38f53934a10"
  acr_name                   = "crreoridentityprod"
  acr_resource_group_name    = "rg-identity-01"
  postgres_admin_password    = "TestOnly-NotARealPassword123!"
  database_connection_string = "Host=test.invalid;Database=tripper;Username=test;Password=test;SSL Mode=Require"
}

run "private_database_and_secret_contract" {
  command = apply

  assert {
    condition     = azurerm_postgresql_flexible_server.tripper.public_network_access_enabled == false
    error_message = "PostgreSQL must not expose a public endpoint."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.tripper.delegated_subnet_id == azurerm_subnet.postgres.id && azurerm_postgresql_flexible_server.tripper.private_dns_zone_id == azurerm_private_dns_zone.postgres.id
    error_message = "PostgreSQL must use the private subnet and DNS zone."
  }
  assert {
    condition     = azurerm_container_app_environment.tripper.infrastructure_subnet_id == azurerm_subnet.apps.id
    error_message = "Container Apps must be integrated with the application VNet."
  }
  assert {
    condition     = azurerm_container_app_environment.tripper.logs_destination == "log-analytics" && azurerm_container_app_environment.tripper.log_analytics_workspace_id == azurerm_log_analytics_workspace.tripper.id
    error_message = "Container Apps must explicitly route logs to the configured Log Analytics workspace."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.extensions.name == "azure.extensions" && azurerm_postgresql_flexible_server_configuration.extensions.value == "POSTGIS"
    error_message = "PostGIS must be allow-listed."
  }
  assert {
    condition     = one([for env in azurerm_container_app.backend.template[0].container[0].env : env.secret_name if env.name == "Database__ConnectionString"]) == "database-connection-string"
    error_message = "The database environment variable must reference a secret."
  }
  assert {
    condition     = azurerm_role_assignment.acr_pull.scope == data.azurerm_container_registry.existing.id && azurerm_role_assignment.acr_pull.role_definition_name == "AcrPull"
    error_message = "The pull role must be scoped to the existing cross-subscription registry."
  }
  assert {
    condition     = azurerm_container_app.backend.registry[0].identity == azurerm_user_assigned_identity.acr_pull.id
    error_message = "Registry access must use the user-assigned identity."
  }
  assert {
    condition     = azurerm_resource_group.tripper.location == "uksouth" && azurerm_postgresql_flexible_server.tripper.sku_name == "B_Standard_B1ms" && azurerm_postgresql_flexible_server.tripper.storage_mb == 32768
    error_message = "The default deployment must use UK South and the approved low-traffic database size."
  }
  assert {
    condition     = azurerm_static_web_app.frontend.location == "eastus2"
    error_message = "Frontend hosting must use East US 2 independently of the UK South backend."
  }
}

run "reject_short_password" {
  command = plan
  variables {
    postgres_admin_password = "short"
  }
  expect_failures = [var.postgres_admin_password]
}

run "reject_empty_connection_string" {
  command = plan
  variables {
    database_connection_string = " "
  }
  expect_failures = [var.database_connection_string]
}

run "reject_example_secrets" {
  command = plan
  variables {
    postgres_admin_password    = "REPLACE_WITH_STRONG_PASSWORD"
    database_connection_string = "Host=test.invalid;Password=REPLACE_WITH_STRONG_PASSWORD"
  }
  expect_failures = [var.postgres_admin_password, var.database_connection_string]
}

run "ignore_image_changes_owned_by_release_pipeline" {
  command = plan
  variables {
    bootstrap_image = "crreoridentityprod.azurecr.io/tripper-api:v99.0.0"
  }
  assert {
    condition     = azurerm_container_app.backend.template[0].container[0].image == "mcr.microsoft.com/dotnet/samples:aspnetapp"
    error_message = "Terraform must ignore image changes after creation."
  }
}