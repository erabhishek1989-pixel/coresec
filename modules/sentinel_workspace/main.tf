resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${var.environment_identifier}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  daily_quota_gb      = -1

  tags = var.tags
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel_log_analytics_workspace_onboarding" {
  workspace_id                 = azurerm_log_analytics_workspace.log_analytics_workspace.id
  customer_managed_key_enabled = false

  depends_on = [azurerm_log_analytics_workspace.log_analytics_workspace]
}

resource "azurerm_user_assigned_identity" "sentinel_log_analyics_managed_identity" {
  name                = "${var.environment_identifier}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}


