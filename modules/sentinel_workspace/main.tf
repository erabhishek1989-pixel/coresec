terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

#=======================WORKSPACE=====================================

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${var.environment_identifier}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  daily_quota_gb      = -1
  tags                = var.tags
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
  tags                = var.tags
}

#====================== DATA CONNECTORS======================================

# Get Key Vault
data "azurerm_key_vault" "connector_kv" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled && v.key_vault_name != null
  }

  name                = each.value.key_vault_name
  resource_group_name = each.value.key_vault_resource_group
}

# Get Secrets
data "azurerm_key_vault_secret" "connector_secrets" {
  for_each = local.connector_secret_references

  name         = each.value.secret_name
  key_vault_id = data.azurerm_key_vault.connector_kv[each.value.connector_key].id
}

# Storage Account
resource "azurerm_storage_account" "connector_functions" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled
  }

  name                     = lower(replace("${var.environment_identifier}stfn${each.key}", "/[^a-z0-9]/", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "connector_functions" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled
  }

  name                = "${var.environment_identifier}-asp-sentinel-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = try(each.value.config.function_sku, "Y1")
  tags                = var.tags
}

# Function App
resource "azurerm_linux_function_app" "connector_functions" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled
  }

  name                       = "${var.environment_identifier}-func-sentinel-${each.key}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.connector_functions[each.key].id
  storage_account_name       = azurerm_storage_account.connector_functions[each.key].name
  storage_account_access_key = azurerm_storage_account.connector_functions[each.key].primary_access_key

  site_config {
    application_stack {
      python_version = try(each.value.config.python_version, "3.9")
    }
    always_on = try(each.value.config.function_sku, "Y1") != "Y1" ? true : false
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(
    {
      "WORKSPACE_ID"                   = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
      "WORKSPACE_KEY"                  = var.workspace_shared_key_secret_uri != null ? "@Microsoft.KeyVault(SecretUri=${var.workspace_shared_key_secret_uri})" : ""
      "FUNCTIONS_WORKER_RUNTIME"       = try(each.value.config.runtime, "python")
      "FUNCTIONS_EXTENSION_VERSION"    = try(each.value.config.extension_version, "~4")
      "APPINSIGHTS_INSTRUMENTATIONKEY" = try(var.application_insights_key, "")
    },
    try(each.value.config.app_settings, {}),
    each.value.endpoint != null ? { "CONNECTOR_ENDPOINT" = each.value.endpoint } : {},
    {
      for secret_key, secret_name in try(each.value.secrets, {}) :
      upper(replace(secret_key, "-", "_")) => "@Microsoft.KeyVault(SecretUri=https://${each.value.key_vault_name}.vault.azure.net/secrets/${secret_name})"
    }
  )

  tags = merge(
    var.tags,
    {
      "connector_type" = each.value.connector_type
      "connector_name" = each.key
    }
  )

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Key Vault Access
resource "azurerm_key_vault_access_policy" "function_key_vault_access" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled && v.key_vault_name != null
  }

  key_vault_id = data.azurerm_key_vault.connector_kv[each.key].id
  tenant_id    = var.tenant_id
  object_id    = azurerm_linux_function_app.connector_functions[each.key].identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# Deploy Code
resource "null_resource" "deploy_function_code" {
  for_each = {
    for k, v in var.connectors : k => v
    if v.enabled && try(v.config.function_code_url, null) != null
  }

  triggers = {
    function_app_id = azurerm_linux_function_app.connector_functions[each.key].id
    code_url        = each.value.config.function_code_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Deploying ${each.value.connector_type} connector code..."
      sleep 30
      az functionapp deployment source config-zip \
        --resource-group ${var.resource_group_name} \
        --name ${azurerm_linux_function_app.connector_functions[each.key].name} \
        --src ${each.value.config.function_code_url} \
        --timeout 600
      echo "Code deployed for ${each.key}"
    EOT
  }

  depends_on = [
    azurerm_linux_function_app.connector_functions,
    azurerm_key_vault_access_policy.function_key_vault_access
  ]
}

#=======================LOCALS=====================================

locals {
  connector_secret_references = merge([
    for connector_key, connector in var.connectors : {
      for secret_key, secret_name in try(connector.secrets, {}) :
      "${connector_key}_${secret_key}" => {
        connector_key = connector_key
        secret_key    = secret_key
        secret_name   = secret_name
      }
    } if connector.enabled && connector.key_vault_name != null
  ]...)

  connector_secrets = {
    for connector_key, connector in var.connectors : connector_key => {
      for secret_key, secret_name in try(connector.secrets, {}) :
      secret_key => data.azurerm_key_vault_secret.connector_secrets["${connector_key}_${secret_key}"].value
    } if connector.enabled && connector.key_vault_name != null
  }
}
