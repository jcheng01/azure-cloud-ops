data "azurerm_resource_group" "cloudops" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "cloudops" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.cloudops.location
  resource_group_name = data.azurerm_resource_group.cloudops.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "cloudops" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.cloudops.name
  virtual_network_name = azurerm_virtual_network.cloudops.name
  address_prefixes     = [each.value]
}
