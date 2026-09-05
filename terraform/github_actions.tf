resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-github-cloudops-deploy"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  location            = data.azurerm_resource_group.cloudops_prod.location

  tags = local.production_tags
}

resource "azurerm_federated_identity_credential" "github_actions_main" {
  name                = "github-main"
  resource_group_name = data.azurerm_resource_group.cloudops_prod.name
  parent_id           = azurerm_user_assigned_identity.github_actions.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = "https://token.actions.githubusercontent.com"
  subject  = "repo:jcheng01/azure-cloud-ops:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_actions_function_deploy" {
  scope                = azurerm_function_app_flex_consumption.cloudops.id
  role_definition_name             = "Website Contributor"
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

output "github_actions_client_id" {
  description = "Client ID used by GitHub Actions for Azure OIDC login."
  value       = azurerm_user_assigned_identity.github_actions.client_id
}

output "github_actions_tenant_id" {
  description = "Tenant ID used by GitHub Actions for Azure OIDC login."
  value       = azurerm_user_assigned_identity.github_actions.tenant_id
}

output "github_actions_subscription_id" {
  description = "Subscription ID containing the Function App."
  value       = var.subscription_id
}
