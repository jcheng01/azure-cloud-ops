output "resource_group" {
  description = "Existing resource group used by the network."
  value = {
    id       = data.azurerm_resource_group.cloudops.id
    name     = data.azurerm_resource_group.cloudops.name
    location = data.azurerm_resource_group.cloudops.location
  }
}

output "virtual_network" {
  description = "Created CloudOps virtual network."
  value = {
    id            = azurerm_virtual_network.cloudops.id
    name          = azurerm_virtual_network.cloudops.name
    address_space = azurerm_virtual_network.cloudops.address_space
  }
}

output "subnets" {
  description = "Created CloudOps subnets keyed by subnet name."
  value = {
    for name, subnet in azurerm_subnet.cloudops : name => {
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}

output "network_security_groups" {
  description = "Created network security groups keyed by subnet name."
  value = {
    for subnet_name, nsg in azurerm_network_security_group.cloudops : subnet_name => {
      id   = nsg.id
      name = nsg.name
    }
  }
}
