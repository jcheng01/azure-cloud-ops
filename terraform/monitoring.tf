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

resource "azurerm_monitor_action_group" "cloudops" {
  name                = "ag-azure-cloudops"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  short_name          = "cloudops"

  email_receiver {
    name                    = "CloudOpsOwner"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }

  tags = local.production_tags
}

resource "azurerm_monitor_metric_alert" "function_http_5xx" {
  name                = "alert-function-http-5xx"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  scopes              = [azurerm_function_app_flex_consumption.cloudops.id]
  description         = "Alerts when the CloudOps Function App returns an HTTP 5xx response."
  severity            = 2
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.cloudops.id
  }

  tags = local.production_tags
}
