variable "location" {
  type    = string
  default = "eastus"
}

data "azuread_domains" "aad_domains" {}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

data "azurerm_subscription" "current" {}