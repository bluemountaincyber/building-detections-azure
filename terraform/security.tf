resource "azurerm_log_analytics_workspace" "law" {
  name                = "securitymonitoring"
  location            = azurerm_resource_group.workshop_rg.location
  resource_group_name = azurerm_resource_group.workshop_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.workshop_rg.location
  resource_group_name   = azurerm_resource_group.workshop_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

data "azuread_service_principal" "security_insight" {
  display_name = "Azure Security Insights"
}

resource "azurerm_role_assignment" "sentinel_automation_contributor" {
  scope                = azurerm_resource_group.workshop_rg.id
  role_definition_name = "Microsoft Sentinel Automation Contributor"
  principal_id         = data.azuread_service_principal.security_insight.object_id
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "onboarding" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_sentinel_alert_rule_scheduled" "analytic" {
  name                       = "4f752c74-b7a6-47f0-b952-7dcb02cb7f14"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.onboarding.workspace_id
  description                = "Backup Rule - Detects when a file in a sensitive Blob Storage location is read. This can indicate stolen user credential or an insider threat. False-positives can be triggered by legitimate file access operations."
  display_name               = "BACKUP - StorageAccounts - BlobRead operation on sensitive file detected"
  severity                   = "Medium"
  query                      = <<QUERY
StorageBlobLogs
| where AccountName startswith "proddata"
| where OperationName == "GetBlob"
| where ObjectKey endswith "final-instructions.txt"
| extend AttackerIP = split(CallerIpAddress,':')[0]
| sort by TimeGenerated desc
QUERY
  enabled = false
  tactics = [
    "Discovery"
  ]
  techniques = [
    "T1619"
  ]

  entity_mapping {
    entity_type = "IP"
    field_mapping {
      identifier = "Address"
      column_name = "AttackerIP"
    }
  }

  entity_mapping {
    entity_type = "AzureResource"
    field_mapping {
      identifier = "ResourceId"
      column_name = "_ResourceId"
    }
  }

  event_grouping {
    aggregation_method = "AlertPerResult"
  }

  incident_configuration {
    create_incident = true
    grouping {
      enabled = false
    }
  }

  query_frequency = "PT15M"
  query_period = "PT15M"
}
