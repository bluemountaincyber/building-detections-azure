terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.55.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.38.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "=1.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "workshop_rg" {
  name     = "DetectionWorkshop"
  location = var.location
}
