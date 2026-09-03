locals {
  subnet_nsg_map = {
    snet-web  = "nsg-web"
    snet-app  = "nsg-app"
    snet-data = "nsg-data"
  }

  inbound_security_rules = {
    allow_https_internet_to_web = {
      name                       = "allow-https-internet"
      subnet_key                 = "snet-web"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "Internet"
      destination_address_prefix = "10.20.1.0/24"
      destination_port_range     = "443"
    }
    deny_vnet_to_web = {
      name                       = "deny-other-vnet-inbound"
      subnet_key                 = "snet-web"
      priority                   = 4000
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "10.20.1.0/24"
      destination_port_range     = "*"
    }
    allow_web_to_app = {
      name                       = "allow-web-to-app"
      subnet_key                 = "snet-app"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "10.20.1.0/24"
      destination_address_prefix = "10.20.2.0/24"
      destination_port_range     = "8080"
    }
    deny_vnet_to_app = {
      name                       = "deny-other-vnet-inbound"
      subnet_key                 = "snet-app"
      priority                   = 4000
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "10.20.2.0/24"
      destination_port_range     = "*"
    }
    allow_app_to_data = {
      name                       = "allow-app-to-data"
      subnet_key                 = "snet-data"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "10.20.2.0/24"
      destination_address_prefix = "10.20.3.0/24"
      destination_port_range     = "443"
    }
    deny_vnet_to_data = {
      name                       = "deny-other-vnet-inbound"
      subnet_key                 = "snet-data"
      priority                   = 4000
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "10.20.3.0/24"
      destination_port_range     = "*"
    }
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

resource "azurerm_network_security_rule" "inbound" {
  for_each = local.inbound_security_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = data.azurerm_resource_group.cloudops.name
  network_security_group_name = azurerm_network_security_group.cloudops[each.value.subnet_key].name
}
