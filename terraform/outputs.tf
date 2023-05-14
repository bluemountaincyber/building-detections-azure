output "sp_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "sp_client_id" {
  value = azuread_application.storage_manager.application_id
}

output "sp_password" {
  value     = azuread_service_principal_password.storage_manager_password.value
  sensitive = true
}
