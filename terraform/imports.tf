locals {
  import_network_base = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network"
}

# Import the three existing subnets.
import {
  for_each = var.subnets

  to = azurerm_subnet.cloudops[each.key]
  id = "${local.import_network_base}/virtualNetworks/${var.vnet_name}/subnets/${each.key}"
}

# Import the three existing NSGs.
import {
  for_each = local.subnet_nsg_map

  to = azurerm_network_security_group.cloudops[each.key]
  id = "${local.import_network_base}/networkSecurityGroups/${each.value}"
}

# Import each existing subnet-to-NSG association.
# Azure identifies this association using the subnet's resource ID.
import {
  for_each = local.subnet_nsg_map

  to = azurerm_subnet_network_security_group_association.cloudops[each.key]
  id = "${local.import_network_base}/virtualNetworks/${var.vnet_name}/subnets/${each.key}"
}

# Import the six existing custom inbound rules.
import {
  for_each = local.inbound_security_rules

  to = azurerm_network_security_rule.inbound[each.key]
  id = "${local.import_network_base}/networkSecurityGroups/${local.subnet_nsg_map[each.value.subnet_key]}/securityRules/${each.value.name}"
}

import {
  to = azurerm_static_web_app.dashboard
  id = "/subscriptions/62e0da42-37c5-4727-a0dd-34c0e5d1c92d/resourceGroups/rg-azure-cloudops-prod/providers/Microsoft.Web/staticSites/swa-azure-cloudops"
}