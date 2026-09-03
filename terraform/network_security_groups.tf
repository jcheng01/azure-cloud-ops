locals {
  subnet_nsg_map = {
    snet-web  = "nsg-web"
    snet-app  = "nsg-app"
    snet-data = "nsg-data"
  }
}

resource "azurerm_network_security_group" "cloudops" {
  for_each = local.subnet_nsg_map

  name                = each.value
  location            = data.azurerm_resource_group.cloudops.location
  resource_group_name = data.azurerm_resource_group.cloudops.name

  tags = merge(var.tags, {
    Tier = trimprefix(each.key, "snet-")
  })
}

resource "azurerm_subnet_network_security_group_association" "cloudops" {
  for_each = local.subnet_nsg_map

  subnet_id                 = azurerm_subnet.cloudops[each.key].id
  network_security_group_id = azurerm_network_security_group.cloudops[each.key].id
}
