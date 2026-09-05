locals {
  production_tags = merge(var.tags, {
    Environment = "Production"
    Component   = "LiveAPI"
  })
}

resource "azurerm_storage_account" "function" {
  name                = "stcloudopsfuncjcheng01"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = "East US 2"

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true

  tags = local.production_tags
}

resource "azurerm_storage_container" "function_releases" {
  name                  = "function-releases"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "function" {
  name                = "plan-azure-cloudops-flex"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = "East US 2"

  os_type  = "Linux"
  sku_name = "FC1"

  tags = local.production_tags
}

resource "azurerm_function_app_flex_consumption" "cloudops" {
  name                = "func-azure-cloudops-jcheng01"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = "East US 2"
  service_plan_id     = azurerm_service_plan.function.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.function.primary_blob_endpoint}${azurerm_storage_container.function_releases.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.function.primary_access_key

  runtime_name           = "node"
  runtime_version        = "22"
  instance_memory_in_mb  = 512
  maximum_instance_count = 5

  https_only                    = true
  public_network_access_enabled = true

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.function.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    AZURE_SUBSCRIPTION_ID                      = var.subscription_id
    RESOURCE_GROUP_NAME                        = data.azurerm_resource_group.cloudops.name
    PRODUCTION_RESOURCE_GROUP_NAME             = data.azurerm_resource_group.cloudops_prod.name
    FUNCTION_RESOURCE_ID                       = "/subscriptions/${var.subscription_id}/resourceGroups/${data.azurerm_resource_group.cloudops_prod.name}/providers/Microsoft.Web/sites/func-azure-cloudops-jcheng01"
    MONTHLY_BUDGET                             = tostring(var.monthly_budget_amount)
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    http2_enabled           = true

    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.dashboard.default_host_name}"
      ]

      support_credentials = false
    }
  }

  tags = local.production_tags
}

resource "azurerm_role_assignment" "function_reader" {
  scope                = data.azurerm_resource_group.cloudops.id
  role_definition_name = "Reader"
  principal_id         = azurerm_function_app_flex_consumption.cloudops.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "function_prod_reader" {
  scope                = data.azurerm_resource_group.cloudops_prod.id
  role_definition_name = "Reader"
  principal_id         = azurerm_function_app_flex_consumption.cloudops.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
