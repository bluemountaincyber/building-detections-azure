resource "azuread_application" "storage_manager" {
  display_name = "Storage Manager"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "storage_manager_sp" {
  application_id               = azuread_application.storage_manager.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "storage_manager_password" {
  service_principal_id = azuread_service_principal.storage_manager_sp.object_id
}

resource "azurerm_role_assignment" "mhooper_storage_read" {
  scope                = azurerm_storage_account.prod_data.id
  role_definition_name = "Reader and Data Access"
  principal_id         = azuread_service_principal.storage_manager_sp.id
}

resource "azurerm_role_assignment" "current_user_storage_read" {
  scope                = azurerm_storage_account.prod_data.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azuread_client_config.current.object_id
}