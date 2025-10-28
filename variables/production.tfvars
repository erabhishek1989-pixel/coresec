environment                     = "Production"
environment_identifier          = "y3"
subscription_id                 = "9d569d3f-4846-43ac-94ad-19ac3c8676a9"
tenant_id                       = "fb973a23-5188-45ab-b4fb-277919443584"
core_management_subscription_id = "2bdf8cf8-7375-4406-96af-ececefba1dbe"

infrastructure_client_id = "cf42de7e-6179-43f5-8e16-84c2e3665ea8"


### NETWORKING ###

virtual_networks_dns_servers = ["10.0.0.116", "172.21.112.10"]

virtual_networks = {
  "vnet-core-security-uksouth-0001" = {
    name          = "y3-vnet-core-security-uksouth-0001"
    location      = "UK South"
    address_space = ["10.0.60.0/24"]
    peerings = {
      "core-security-uksouth-to-core-uksouth" = {
        name        = "peer_prod_vnet_core_security_uksouth_to_y3_core_networking_uksouth"
        remote_peer = false
      },
      "core-uksouth-to-core-security-uksouth" = {
        name        = "peer_y3_core_networking_uksouth_to_prod_vnet_core_security_uksouth"
        remote_peer = true
      }
    }
    subnets = {
      "snet-core-security-uksouth-avd" = {
        name             = "y3-snet-core-security-uksouth-avd"
        address_prefixes = ["10.0.60.0/27"]
      }
    }
    route_tables = {
      "route-core-security" = {
        name = "y3-route-core-security-uksouth-0001"
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
  "vnet-core-security-ukwest-0001" = {
    name          = "y3-vnet-core-security-ukwest-0001"
    location      = "UK West"
    address_space = ["10.2.60.0/24"]
    peerings = {
      "core-security-ukwest-to-core-ukwest" = {
        name        = "peer_prod_vnet_core_security_ukwest_to_y3_core_networking_ukwest"
        remote_peer = false
      },
      "core-ukwest-to-core-security-ukwest" = {
        name        = "peer_y3_core_networking_ukwest_to_prod_core_security_ukwest"
        remote_peer = true
      }
    }
    subnets = {
      "snet-core-security-ukwest-avd" = {
        name             = "y3-snet-core-security-ukwest-avd"
        address_prefixes = ["10.2.60.0/27"]
      }
    }
    route_tables = {
      "route-core-security" = {
        name = "y3-route-core-security-ukwest-0001"
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
#======================SENTINEL DATA CONNECTORS======================================

sentinel_connectors = {
  # CyberArk Connector
  "cyberark-audit" = {
    enabled                  = true
    connector_type           = "CyberArk"
    key_vault_name           = "y3-kv-coremgt-uks-0001"
    key_vault_resource_group = "y3-rg-core-management-uksouth-0001"
    endpoint                 = "https:/-CYBERARK-ENDPOINT.com"  # need to update

    secrets = {
      username = "cyberark-api-username"
      password = "cyberark-api-password"
    }

    config = {
      function_code_url = "https://aka.ms/sentinel-CyberArkEPV-functionapp"
      function_sku      = "Y1"
      python_version    = "3.9"
      runtime           = "python"
    }
  }

  # Mimecast Connector (Terraform-managed, different from manual!)
  "mimecast-audit-tf" = {
    enabled                  = true
    connector_type           = "Mimecast"
    key_vault_name           = "y3-kv-coremgt-uks-0001"
    key_vault_resource_group = "y3-rg-core-management-uksouth-0001"
    endpoint                 = "https://api.mimecast.com"

    secrets = {
      application_id  = "mimecast-audit-application-id"
      application_key = "mimecast-audit-application-key"
      access_key      = "mimecast-audit-access-key"
      secret_key      = "mimecast-audit-secret-key"
    }

    config = {
      function_code_url = "https://aka.ms/sentinel-MimecastAudit-functionapp"
      function_sku      = "Y1"
      python_version    = "3.9"
      runtime           = "python"
    }
  }
}
