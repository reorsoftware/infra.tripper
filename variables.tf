variable "subscription_id" {
  type        = string
  description = "Subscription containing Tripper resources."
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant used by both subscriptions."
}

variable "location" {
  type        = string
  description = "Azure region for backend infrastructure."
  default     = "uksouth"
}

variable "name_prefix" {
  type        = string
  description = "Application prefix used in resource names."
  default     = "tripper"
}

variable "name_suffix" {
  type        = string
  description = "Regional suffix; this is a single environment."
  default     = "uks"
}

variable "unique_suffix" {
  type        = string
  description = "Suffix for globally unique PostgreSQL server names."
  default     = "6ab40698"
}

variable "resource_names" {
  type        = map(string)
  description = "Optional overrides: resource_group, vnet, apps_subnet, postgres_subnet, logs, environment, app, identity, postgres, static_web_app."
  default     = {}
}

variable "acr_subscription_id" {
  type        = string
  description = "Subscription containing the existing registry."
}

variable "acr_name" {
  type        = string
  description = "Existing container registry name (not created or imported here)."
}

variable "acr_resource_group_name" {
  type        = string
  description = "Resource group containing the existing registry."
}

variable "postgres_admin_username" {
  type        = string
  description = "PostgreSQL administrator username."
  default     = "tripperadmin"
}

variable "postgres_admin_password" {
  type        = string
  description = "Set locally or through TF_VAR_postgres_admin_password; never commit."
  sensitive   = true
  validation {
    condition     = length(var.postgres_admin_password) >= 8 && length(var.postgres_admin_password) <= 128 && !startswith(var.postgres_admin_password, "REPLACE_")
    error_message = "Replace the placeholder with a PostgreSQL administrator password containing 8–128 characters."
  }
}

variable "database_connection_string" {
  type        = string
  description = "Npgsql connection string, including Host, Database, Username, Password and SSL Mode=Require; stored as a Container App secret."
  sensitive   = true
  validation {
    condition     = length(trimspace(var.database_connection_string)) > 0 && !strcontains(var.database_connection_string, "REPLACE_")
    error_message = "A nonempty backend database connection string without placeholder values is required."
  }
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL major version."
  default     = "17"
}

variable "postgres_sku_name" {
  type        = string
  description = "Burstable B1ms for low traffic; change if more capacity is needed."
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type        = number
  description = "PostgreSQL allocated storage in MB."
  default     = 32768
}

variable "postgres_backup_retention_days" {
  type        = number
  description = "Automatic database backup retention."
  default     = 7
}

variable "database_name" {
  type        = string
  description = "Application database name."
  default     = "tripper"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Private application network address space."
  default     = ["10.42.0.0/16"]
}

variable "apps_subnet_prefixes" {
  type        = list(string)
  description = "Dedicated Container Apps workload-profile subnet, at least /27."
  default     = ["10.42.0.0/23"]
}

variable "postgres_subnet_prefixes" {
  type        = list(string)
  description = "Dedicated delegated PostgreSQL subnet."
  default     = ["10.42.2.0/24"]
}

variable "bootstrap_image" {
  type        = string
  description = "Fixed public starter image for first creation only; releases are owned by the application pipeline."
  default     = "mcr.microsoft.com/dotnet/samples:aspnetapp"
}

variable "container_port" {
  type        = number
  description = "Backend listening port; ASPNETCORE_HTTP_PORTS is also set to this value."
  default     = 8080
}

variable "container_cpu" {
  type        = number
  description = "Consumption workload CPU allocation."
  default     = 0.25
}

variable "container_memory" {
  type        = string
  description = "Consumption workload memory allocation, matched to CPU."
  default     = "0.5Gi"
}

variable "container_min_replicas" {
  type        = number
  description = "Zero allows scale-to-zero for low traffic."
  default     = 0
}

variable "container_max_replicas" {
  type        = number
  description = "Upper bound for backend scaling."
  default     = 2
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention period."
  default     = 30
}

variable "static_web_app_location" {
  type        = string
  description = "SWA control-plane region; use a supported region, independent of backend location."
  default     = "eastus2"
}

variable "static_web_app_sku" {
  type        = string
  description = "Static Web App SKU (Free or Standard)."
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku)
    error_message = "Static Web App SKU must be Free or Standard."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags added to provisioned resources."
  default     = { application = "tripper", managed-by = "terraform" }
}
