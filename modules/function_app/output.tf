output "function_app_id" {
  value = azurerm_linux_function_app.function_app.id
}

output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.function_app.default_hostname
}

output "function_app_identity_principal_id" {
  value = azurerm_linux_function_app.function_app.identity[0].principal_id
}

output "service_plan_id" {
  value = azurerm_service_plan.app_service_plan.id
}