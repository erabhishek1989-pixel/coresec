environment                     = "Development"
environment_identifier          = "d3"
subscription_id                 = "5efb4946-5bab-4ca6-8a95-834a1c20f0ce"
tenant_id                       = "4a8844b6-d4c9-4028-8eca-acae232ae569"
core_management_subscription_id = "24e769ee-78cf-4a8d-8f6c-05a315caab79" # This is the SharePoint subscription as there isn't a Core subscription at this time


infrastructure_client_id = "713150f6-f45d-42a2-969c-2acc6d6d644c"


### NETWORKING ###

virtual_networks_dns_servers = ["10.0.0.116", "172.21.112.10"]

virtual_networks = {
  "vnet-workday-uksouth-0001" = {
    name          = "d3-vnet-workday-uksouth-0001"
    location      = "UK South"
    address_space = ["10.0.56.0/24"]
    peerings = {
      "workday_uksouth_to_core_uksouth" = {
        name        = "peer_dev_vnet_workday_uksouth_to_y3_core_networking_uksouth"
        remote_peer = false
      },
      "core_uksouth_to_workday_uksouth" = {
        name        = "peer_y3_core_networking_uksouth_to_dev_vnet_workday_uksouth"
        remote_peer = true
      }
    }
    subnets = {
      "snet-workday-uksouth-storage" = {
        name             = "d3-snet-workday-uksouth-storage"
        address_prefixes = ["10.0.56.0/28"]
      },
      "snet-workday-uksouth-sql" = {
        name             = "d3-snet-workday-uksouth-sql"
        address_prefixes = ["10.0.56.16/28"]
      },
      "snet-workday-uksouth-keyvault" = {
        name             = "d3-snet-workday-uksouth-keyvault"
        address_prefixes = ["10.0.56.32/28"]
      }
      "snet-workday-uksouth-functionapp" = {
        name             = "d3-snet-workday-uksouth-functionapp"
        address_prefixes = ["10.0.56.64/28"]
        delegation       = ["Microsoft.Web/serverFarms"]
      }
    }
    route_tables = {
      "route-workday-uksouth" = {
        name = "d3-route-workday-uksouth-0001"
        routes = {
          "default" = {
            name                   = "default"
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.0.0.4"
          }
        }
      }
    }
  },
  "vnet-workday-ukwest-0001" = {
    name          = "d3-vnet-workday-ukwest-0001"
    location      = "UK West"
    address_space = ["10.2.56.0/24"]
    peerings = {
      "workday_ukwest_to_core_ukwest" = {
        name        = "peer_dev_vnet_workday_ukwest_to_y3_core_networking_ukwest"
        remote_peer = false
      },
      "core_ukwest_to_workday_ukwest" = {
        name        = "peer_y3_core_networking_ukwest_to_dev_vnet_workday_ukwest"
        remote_peer = true
      }
    }
    subnets = {
      "snet-workday-ukwest-storage" = {
        name             = "d3-snet-workday-ukwest-storage"
        address_prefixes = ["10.2.56.0/28"]
      },
      "snet-workday-uksouth-sql" = {
        name             = "d3-snet-workday-ukwest-sql"
        address_prefixes = ["10.2.56.16/28"]
      },
      "snet-workday-ukwest-keyvault" = {
        name             = "d3-snet-workday-ukwest-keyvault"
        address_prefixes = ["10.2.56.32/28"]
      }
      "snet-workday-ukwest-functionapp" = {
        name             = "d3-snet-workday-ukwest-functionapp"
        address_prefixes = ["10.2.56.64/28"]
      }
    }
    route_tables = {
      "route-workday-uksouth" = {
        name = "d3-route-workday-ukwest-0001"
        routes = {
          "default" = {
            name                   = "default"
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.0.0.4"
          }
        }
      }
    }
  }
}
