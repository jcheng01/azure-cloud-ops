output "resource_group" {
  description = "Existing resource group used by the network."
  value = {
    id       = data.azurerm_resource_group.cloudops.id
    name     = data.azurerm_resource_group.cloudops.name
    location = data.azurerm_resource_group.cloudops.location
  }
}

output "virtual_network" {
  description = "CloudOps virtual network."
  value = {
    id            = azurerm_virtual_network.cloudops.id
    name          = azurerm_virtual_network.cloudops.name
    address_space = azurerm_virtual_network.cloudops.address_space
  }
}

output "subnets" {
  description = "CloudOps subnets keyed by subnet name."
  value = {
    for name, subnet in azurerm_subnet.cloudops : name => {
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}

output "network_security_groups" {
  description = "Network security groups keyed by subnet name."
  value = {
    for subnet_name, nsg in azurerm_network_security_group.cloudops : subnet_name => {
      id   = nsg.id
      name = nsg.name
    }
  }
}

output "monitoring" {
  description = "Azure Monitor resources used by the production Function App."
  value = {
    log_analytics_workspace = azurerm_log_analytics_workspace.cloudops.name
    application_insights    = azurerm_application_insights.function.name
    action_group            = azurerm_monitor_action_group.cloudops.name
    http_5xx_alert          = azurerm_monitor_metric_alert.function_http_5xx.name
  }
}

output "governance" {
  description = "Audit-only policy assignments protecting both CloudOps resource groups."
  value = {
    required_tags = {
      for key, assignment in azurerm_resource_group_policy_assignment.required_tags :
      key => assignment.name
    }
    allowed_locations = {
      for key, assignment in azurerm_resource_group_policy_assignment.allowed_locations :
      key => assignment.name
    }
  }
}

output "cost_management" {
  description = "Monthly CloudOps subscription budget."
  value = {
    name   = azurerm_consumption_budget_subscription.cloudops.name
    amount = azurerm_consumption_budget_subscription.cloudops.amount
  }
}
