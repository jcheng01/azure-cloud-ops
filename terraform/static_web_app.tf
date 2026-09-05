data "azurerm_resource_group" "cloudops_prod" {
  name = "rg-azure-cloudops-prod"
}

resource "azurerm_static_web_app" "dashboard" {
  name                = "swa-azure-cloudops"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = "East US 2"

  sku_tier = "Free"
  sku_size = "Free"

  tags = local.production_tags

  lifecycle {
    ignore_changes = [
      repository_url,
      repository_branch,
      repository_token
    ]
  }
}
