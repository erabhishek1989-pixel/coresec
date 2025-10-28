output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

output "log_analytics_workspace" {
  description = "Full workspace object"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace
}

output "workspace_id" {
  description = "Workspace ID (GUID)"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
}

output "function_apps" {
  description = "Function Apps created"
  value = {
    for k, v in azurerm_linux_function_app.connector_functions : k => {
      id                    = v.id
      name                  = v.name
      default_hostname      = v.default_hostname
      identity_principal_id = v.identity[0].principal_id
    }
  }
}
