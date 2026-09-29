variable "subscription_id" {
  type        = string
  description = "Subscription hosting Terraform state."
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant for state authentication."
}

variable "state_admin_object_id" {
  type        = string
  description = "Object ID (not application/client ID) of the Azure user running bootstrap."
}

variable "resource_group_name" {
  type        = string
  description = "Separate resource group for remote state."
  default     = "rg-tripper-tfstate-uks"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name, 3–24 lowercase alphanumeric characters."
  default     = "sttripperstate6ab40698"
}

variable "container_name" {
  type        = string
  description = "Private blob container used for Terraform state."
  default     = "tfstate"
}

variable "location" {
  type        = string
  description = "State storage region."
  default     = "uksouth"
}

variable "tags" {
  type        = map(string)
  description = "Tags for state resources."
  default     = { application = "tripper", managed-by = "terraform" }
}
