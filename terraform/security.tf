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
  name                       = "saBlobReadSensitive"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.onboarding.workspace_id
  display_name               = "Detects when a file in a sensitive Blob Storage location is read. This can indicate stolen user credential or an insider threat. False-positives can be triggered by legitimate file access operations."
  severity                   = "Medium"
  query                      = <<QUERY
StorageBlobLogs
| where AccountName == "productiondatamain"
| where OperationName == "GetBlob"
| where ObjectKey startswith "/productiondatamain/secretdata/"
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
