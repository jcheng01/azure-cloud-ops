resource "azurerm_log_analytics_workspace" "cloudops" {
  name                = "log-azure-cloudops-prod"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = data.azurerm_resource_group.cloudops_prod.location

  sku               = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb    = 0.5

  tags = local.production_tags
}

resource "azurerm_application_insights" "function" {
  name                = "appi-azure-cloudops"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = data.azurerm_resource_group.cloudops_prod.location
  workspace_id        = azurerm_log_analytics_workspace.cloudops.id
  application_type    = "web"

  retention_in_days   = 30
  sampling_percentage = 100

  tags = local.production_tags
}

resource "azurerm_monitor_diagnostic_setting" "function" {
  name                       = "diag-function-to-log-analytics"
  target_resource_id         = azurerm_function_app_flex_consumption.cloudops.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cloudops.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
