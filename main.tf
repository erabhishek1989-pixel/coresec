#--------------- PROVIDER DETAILS ---------------#

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "core-management"
  tenant_id       = var.tenant_id
  subscription_id = var.core_management_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "y3-core-networking"
  tenant_id       = "fb973a23-5188-45ab-b4fb-277919443584"
  subscription_id = "1753c763-47da-4014-991c-4b094cababda"
  features {}
}

#provider "azuread" {
#  tenant_id     = var.tenant_id
#  client_secret = data.azurerm_key_vault_secret.terraform_app_client.value
#  client_id     = var.infrastructure_client_id
#}

data "azurerm_client_config" "current" {
}

output "account_id" {
  value = data.azurerm_client_config.current.client_id
}

data "azuread_client_config" "current" {}

output "object_id" {
  value = data.azuread_client_config.current.object_id
}

terraform {
  backend "azurerm" {}
}

#--------------- CURRENT TIMESTAMP ---------------#

resource "time_static" "time_now" {}

output "current_time" {
  value = time_static.time_now.rfc3339
}

#--------------- TAGS ---------------#

locals {
  common_tags = {
    Application    = "Security"
    Environment    = var.environment
    Owner          = "Infrastructure"
    Classification = "Company Confidential"
    LastUpdated    = time_static.time_now.rfc3339
  }

  extra_tags = {
  }
}

#--------------- DEPLOYMENT ---------------#

#--------------- Resource Groups ---------------#

module "resource_groups" {
  source = "./modules/resourcegroups"

  for_each               = var.resource_groups_map
  rgname                 = each.value.name
  rglocation             = each.value["location"]
  environment_identifier = var.environment_identifier
  tags                   = merge(local.common_tags, local.extra_tags)
}

# ------------ virtual_networks ------------ #

module "virtual_networks" {
  source   = "./modules/virtual_network"
  for_each = var.virtual_networks

  name                                    = each.value.name
  location                                = each.value.location
  resource_group_name                     = each.value.location == "UK South" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  address_space                           = each.value.address_space
  virtual_networks_dns_servers            = var.virtual_networks_dns_servers
  peerings                                = each.value.peerings
  subnets                                 = each.value.subnets
  route_tables                            = each.value.route_tables
  y3-rg-core-networking-uksouth-0001_name = data.azurerm_resource_group.rg-core-networking-uksouth-0001.name
  y3-rg-core-networking-ukwest-0001_name  = data.azurerm_resource_group.rg-core-networking-ukwest-0001.name
  y3-vnet-core-uksouth-0001_id            = data.azurerm_virtual_network.vnet-core-uksouth-0001.id
  y3-vnet-core-uksouth-0001_name          = data.azurerm_virtual_network.vnet-core-uksouth-0001.name
  y3-vnet-core-ukwest-0001_id             = data.azurerm_virtual_network.vnet-core-ukwest-0001.id
  y3-vnet-core-ukwest-0001_name           = data.azurerm_virtual_network.vnet-core-ukwest-0001.name
  tags                                    = merge(local.common_tags, local.extra_tags)

  providers = {
    azurerm.y3-core-networking = azurerm.y3-core-networking
  }

  depends_on = [
    module.resource_groups
  ]
}

#--------------- sentinel_workspace ---------------#

module "sentinel_workspace" {
  source = "./modules/sentinel_workspace"

  for_each               = var.sentinel_workspace
  name                   = each.value.name
  location               = each.value.location
  sku                    = each.value.sku
  environment_identifier = var.environment_identifier
  resource_group_name    = each.value.location == "UK South" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  tags                   = merge(local.common_tags, local.extra_tags)

  depends_on = [module.resource_groups]
}
#--------------- Sentinel Connector Storage Accounts ---------------#
module "connector_storage_accounts" {
  source = "./modules/storage_account"

  for_each = {
    for k, v in var.sentinel_connectors_config : k => v
    if v.enabled
  }

  name                     = each.value.storage_account_name
  resource_group_name      = each.value.location == "UK South" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  location                 = each.value.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = merge(local.common_tags, local.extra_tags)

  depends_on = [module.resource_groups]
}

#--------------- Sentinel Connector Function Apps ---------------#

data "azurerm_key_vault" "connector_kv" {
  for_each = {
    for k, v in var.sentinel_connectors_config : k => v
    if v.enabled && v.key_vault_name != null
  }

  name                = each.value.key_vault_name
  resource_group_name = each.value.key_vault_resource_group
}

data "azurerm_key_vault_secret" "connector_secrets" {
  for_each = merge([
    for connector_key, connector in var.sentinel_connectors_config : {
      for secret_key, secret_name in try(connector.secrets, {}) :
      "${connector_key}_${secret_key}" => {
        connector_key = connector_key
        secret_name   = secret_name
        key_vault_id  = data.azurerm_key_vault.connector_kv[connector_key].id
      }
    } if connector.enabled && connector.key_vault_name != null
  ]...)

  name         = each.value.secret_name
  key_vault_id = each.value.key_vault_id
}

module "connector_function_apps" {
  source = "./modules/function_app"

  for_each = {
    for k, v in var.sentinel_connectors_config : k => v
    if v.enabled
  }

  function_app_name          = each.value.function_app_name
  service_plan_name          = each.value.service_plan_name
  resource_group_name        = each.value.location == "UK South" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  location                   = each.value.location
  storage_account_name       = module.connector_storage_accounts[each.key].storage_account_name
  storage_account_access_key = module.connector_storage_accounts[each.key].primary_access_key
  sku_name                   = try(each.value.sku_name, "Y1")
  python_version             = try(each.value.python_version, "3.9")
  tenant_id                  = var.tenant_id
  key_vault_id               = each.value.key_vault_name != null ? data.azurerm_key_vault.connector_kv[each.key].id : null

  app_settings = merge(
    {
      "WORKSPACE_ID"                = module.sentinel_workspace["log-core-security-sentinel-uksouth-0001"].workspace_id
      "WORKSPACE_KEY"               = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.workspace_shared_key["log-core-security-sentinel-uksouth-0001"].id})"
      "FUNCTIONS_WORKER_RUNTIME"    = "python"
      "FUNCTIONS_EXTENSION_VERSION" = "~4"
    },
    try(each.value.app_settings, {}),
    {
      for secret_key, secret_name in try(each.value.secrets, {}) :
      upper(replace(secret_key, "-", "_")) => "@Microsoft.KeyVault(SecretUri=https://${each.value.key_vault_name}.vault.azure.net/secrets/${secret_name})"
    }
  )

  tags = merge(
    local.common_tags,
    local.extra_tags,
    {
      "connector_type" = each.value.connector_type
      "connector_name" = each.key
    }
  )

  depends_on = [
    module.connector_storage_accounts,
    module.sentinel_workspace
  ]
}
#--------------- Azure Virtual Desktop ---------------#

module "azure_virtual_desktop" {
  source = "./modules/azure_virtual_desktop"

  for_each = {
    for i, avd in var.azure_virtual_desktop : avd.name => avd
  }
  environment_identifier                 = var.environment_identifier
  name                                   = each.value.name
  resource_group_name                    = each.value.location == "UK SOUTH" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  location                               = each.value.location
  type                                   = each.value.type
  load_balancer_type                     = each.value.load_balancer_type
  maximum_sessions_allowed               = each.value.maximum_sessions_allowed
  description                            = each.value.description
  start_vm_on_connect                    = each.value.start_vm_on_connect
  host_pool_registration_expiration_date = each.value.host_pool_registration_expiration_date
  domain_name                            = each.value.domain_name
  domain_ou_path                         = each.value.domain_ou_path
  domain_restart                         = each.value.domain_restart
  secret_admin_username                  = data.azurerm_key_vault_secret.kv-secret-server-admin-user.value
  secret_admin_password                  = data.azurerm_key_vault_secret.kv-secret-server-admin-password.value
  secret_res_ads_username                = data.azurerm_key_vault_secret.kv-secret-serviceaccount-res-ads-username.value
  secret_res_ads_password                = data.azurerm_key_vault_secret.kv-secret-serviceaccount-res-ads-password.value
  subnet_id                              = each.value.location == "UK SOUTH" ? module.virtual_networks["vnet-core-security-uksouth-0001"].subnet_id["snet-core-security-uksouth-avd"] : module.virtual_networks["vnet-core-security-ukwest-0001"].subnet_id["snet-core-security-ukwest-avd"]
  computer_name                          = each.value.computer_name
  sku                                    = each.value.sku
  instances                              = each.value.instances
  image_publisher                        = each.value.image_publisher
  image_offer                            = each.value.image_offer
  image_sku                              = each.value.image_sku
  image_version                          = each.value.image_version
  license_type                           = each.value.license_type
  tags                                   = merge(local.common_tags, local.extra_tags)
  #virtual_machine_scale_set              = each.value.virtual_machine_scale_set
  #storage_account                        = each.value.storage_account
  depends_on = [module.virtual_networks]
}
