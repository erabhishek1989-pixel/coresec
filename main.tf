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

#--------------- Log Analytics Workspaces ---------------#

module "sentinel_workspace" {
  source = "./modules/sentinel_workspace"

  for_each               = var.sentinel_workspace
  name                   = each.value.name
  location               = each.value.location
  sku                    = each.value.sku
  environment_identifier = var.environment_identifier
  resource_group_name    = each.value.location == "UK South" ? module.resource_groups["rg-core-security-uksouth-0001"].resource_group_name : module.resource_groups["rg-core-security-ukwest-0001"].resource_group_name
  tags                   = merge(local.common_tags, local.extra_tags)
  tenant_id                       = var.tenant_id
  workspace_shared_key_secret_uri = try(azurerm_key_vault_secret.workspace_shared_key[each.key].id, null)
  application_insights_key        = null
  connectors                      = var.sentinel_connectors

  depends_on = [module.resource_groups]
}
#--------------- Store Workspace Key in Key Vault ---------------#

resource "azurerm_key_vault_secret" "workspace_shared_key" {
  for_each = var.sentinel_workspace

  name         = "sentinel-workspace-shared-key-${each.key}"
  value        = module.sentinel_workspace[each.key].log_analytics_workspace.primary_shared_key
  key_vault_id = data.azurerm_key_vault.kv-mgmnt.id

  depends_on = [module.sentinel_workspace]
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
