### CORE NETWORKING INPUTS

### REMOTE STATES ### 
data "terraform_remote_state" "y3-core-networking-ci" {
  backend = "azurerm"

  config = {
    storage_account_name = "y3stcoreterraformuksouth"
    container_name       = "y3coreterraformuksouth"
    resource_group_name  = "y3-rg-terraform-uksouth-001"
    key                  = "y3-core-networking-ci.tfstate"
    subscription_id      = "c8be5642-d14b-47b4-b9ef-8080116b2ed0"
  }
}

data "azurerm_resource_group" "rg-core-networking-uksouth-0001" {
  name     = "y3-rg-core-networking-uksouth-0001"
  provider = azurerm.y3-core-networking
}

data "azurerm_virtual_network" "vnet-core-uksouth-0001" {
  name                = "y3-vnet-core-uksouth-0001"
  resource_group_name = data.azurerm_resource_group.rg-core-networking-uksouth-0001.name
  provider            = azurerm.y3-core-networking
}

data "azurerm_resource_group" "rg-core-networking-ukwest-0001" {
  name     = "y3-rg-core-networking-ukwest-0001"
  provider = azurerm.y3-core-networking
}

data "azurerm_virtual_network" "vnet-core-ukwest-0001" {
  name                = "y3-vnet-core-ukwest-0001"
  resource_group_name = data.azurerm_resource_group.rg-core-networking-ukwest-0001.name
  provider            = azurerm.y3-core-networking
}

data "azurerm_key_vault" "kv-mgmnt" {
  name                = "${var.environment_identifier}-kv-coremgt-uks-0001"
  resource_group_name = "${var.environment_identifier}-rg-core-management-uksouth-0001"
  provider            = azurerm.core-management
}

data "azurerm_key_vault_secret" "terraform_app_client" {
  name         = var.infrastructure_client_id
  key_vault_id = data.azurerm_key_vault.kv-mgmnt.id
}

data "azurerm_key_vault_secret" "kv-secret-server-admin-user" {
  name         = "server-admin-user"
  key_vault_id = "/subscriptions/2bdf8cf8-7375-4406-96af-ececefba1dbe/resourceGroups/y3-rg-core-management-uksouth-0001/providers/Microsoft.KeyVault/vaults/y3-kv-coremgt-uks-0001"
}

data "azurerm_key_vault_secret" "kv-secret-server-admin-password" {
  name         = "server-admin-password"
  key_vault_id = "/subscriptions/2bdf8cf8-7375-4406-96af-ececefba1dbe/resourceGroups/y3-rg-core-management-uksouth-0001/providers/Microsoft.KeyVault/vaults/y3-kv-coremgt-uks-0001"
}

data "azurerm_key_vault_secret" "kv-secret-serviceaccount-res-ads-username" {
  name         = "serviceaccount-res-ads-username"
  key_vault_id = "/subscriptions/2bdf8cf8-7375-4406-96af-ececefba1dbe/resourceGroups/y3-rg-core-management-uksouth-0001/providers/Microsoft.KeyVault/vaults/y3-kv-coremgt-uks-0001"
}

data "azurerm_key_vault_secret" "kv-secret-serviceaccount-res-ads-password" {
  name         = "serviceaccount-res-ads-password"
  key_vault_id = "/subscriptions/2bdf8cf8-7375-4406-96af-ececefba1dbe/resourceGroups/y3-rg-core-management-uksouth-0001/providers/Microsoft.KeyVault/vaults/y3-kv-coremgt-uks-0001"
}
