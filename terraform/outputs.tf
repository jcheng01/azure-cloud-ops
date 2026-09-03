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
