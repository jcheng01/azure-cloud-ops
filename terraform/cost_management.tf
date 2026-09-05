resource "azurerm_consumption_budget_subscription" "cloudops" {
  name            = "budget-azure-cloudops-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-09-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        data.azurerm_resource_group.cloudops.name,
        data.azurerm_resource_group.cloudops_prod.name,
      ]
    }
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_groups = [azurerm_monitor_action_group.cloudops.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_groups = [azurerm_monitor_action_group.cloudops.id]
  }
}
