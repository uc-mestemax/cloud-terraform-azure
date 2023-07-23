output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "connect_ip" {
  value = azurerm_public_ip.public_ip.id
}
