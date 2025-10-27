

# core_tenant_id = "fb973a23-5188-45ab-b4fb-277919443584"

# ---------------------- Resource Groups ---------------------- #

resource_groups_map = {
  "rg-core-security-uksouth-0001" = {
    name     = "rg-core-security-uksouth-0001"
    location = "UK South"
  }
  "rg-core-security-ukwest-0001" = {
    name     = "rg-core-security-ukwest-0001"
    location = "UK West"
  }
}


sentinel_workspace = {
  "log-core-security-sentinel-uksouth-0001" = {
    name     = "log-core-security-sentinel-uksouth-0001"
    location = "UK South"
    sku      = "PerGB2018"
  }
}

sentinel_connectors = {
  "azure_active_directory" = {
    enabled = true
  }
}


#azure_virtual_desktop = {
#  "avd-core-security-uksouth-0001" = {
#    name                                   = "avd-core-security-uksouth-0001"
#    location                               = "UK SOUTH"
#    type                                   = "Pooled"
#    load_balancer_type                     = "DepthFirst"
#    maximum_sessions_allowed               = "1"
#    description                            = "AVD for Microland SOC Access"
#    start_vm_on_connect                    = true
#    host_pool_registration_expiration_date = "2025-02-28T08:00:00Z"
#    domain_name                            = "btuk.local"
#    domain_ou_path                         = "OU=AVD,OU=Datacentre,OU=Servers,OU=National,DC=btuk,DC=local"
#    domain_restart                         = true
#    virtual_machine_scale_set = {
#      "avd-core-security" = {
#        name                 = "avd-core-security"
#        sku                  = "Standard_F4s_v2"
#        instances            = "2"
#        computer_name_prefix = "avd01-"
#        image_publisher      = "MicrosoftWindowsDesktop"
#        image_offer          = "Windows-11"
#        image_sku            = "win11-24h2-avd"
#        image_version        = "latest"
#        license_type         = "Windows_Client"
#
#      }
#    }
#  }
#}


azure_virtual_desktop = {
  "avd-core-security-uksouth-0001" = {
    name                                   = "avd-core-security-uksouth-0001"
    location                               = "UK SOUTH"
    type                                   = "Pooled"
    load_balancer_type                     = "DepthFirst"
    maximum_sessions_allowed               = "1"
    description                            = "AVD for Microland SOC Access"
    start_vm_on_connect                    = true
    host_pool_registration_expiration_date = "2025-02-28T08:00:00Z"
    domain_name                            = "btuk.local"
    domain_ou_path                         = "OU=AVD,OU=Datacentre,OU=Servers,OU=National,DC=btuk,DC=local"
    domain_restart                         = true
    computer_name                          = "avd01"
    sku                                    = "Standard_D8ds_v5"
    instances                              = "2"
    image_publisher                        = "MicrosoftWindowsDesktop"
    image_offer                            = "Windows-11"
    image_sku                              = "win11-24h2-avd"
    image_version                          = "latest"
    license_type                           = "Windows_Client"
  }
}
