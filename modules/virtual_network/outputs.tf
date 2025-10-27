#output "subnet_id" {
#  value = [for subnet in azurerm_subnet.subnet : subnet.id]
#}

output "subnet_id" {
  value = { for name, subnet in azurerm_subnet.subnet : name => subnet.id }
}

output "subnets" {
  value = {
    for i, subnet in azurerm_subnet.subnet : subnet.name => subnet
  }
}
