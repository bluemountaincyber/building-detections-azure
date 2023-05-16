resource "random_string" "storage_account" {
  length  = 16
  special = false
  upper   = false
  lower   = true
  numeric = true
}

resource "azurerm_storage_account" "prod_data" {
  name                     = "proddata${random_string.storage_account.result}"
  resource_group_name      = azurerm_resource_group.workshop_rg.name
  location                 = azurerm_resource_group.workshop_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "hr_docs" {
  name                  = "hr-documents"
  storage_account_name  = azurerm_storage_account.prod_data.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "job_post_pa" {
  name                   = "job-posting-personalassistent-draft.txt"
  storage_account_name   = azurerm_storage_account.prod_data.name
  storage_container_name = azurerm_storage_container.hr_docs.name
  type                   = "Block"
  source                 = "${path.module}/resources/StorageAccount/hr-documents/job-posting-personalassistent-draft.txt"
}

resource "azurerm_storage_blob" "job_post_so" {
  name                   = "job-posting-secops-azure-draft.txt"
  storage_account_name   = azurerm_storage_account.prod_data.name
  storage_container_name = azurerm_storage_container.hr_docs.name
  type                   = "Block"
  source                 = "${path.module}/resources/StorageAccount/hr-documents/job-posting-secops-azure-draft.txt"
}

resource "azurerm_storage_container" "secret_data" {
  name                  = "secretdata"
  storage_account_name  = azurerm_storage_account.prod_data.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "final_instructions" {
  name                   = "final-instructions.txt"
  storage_account_name   = azurerm_storage_account.prod_data.name
  storage_container_name = azurerm_storage_container.secret_data.name
  type                   = "Block"
  source                 = "${path.module}/resources/StorageAccount/secretdata/final-instructions.txt"
}
