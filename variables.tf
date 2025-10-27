variable "environment" {
  type = string
}

variable "resource_groups_map" {
  type = map(object({
    name     = string
    location = string
  }))
}

variable "environment_identifier" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "core_management_subscription_id" {
  type = string
}

variable "infrastructure_client_id" {
  type = string
}

variable "virtual_networks" {
  type = map(object({
    name          = string
    location      = string
    address_space = list(string)

    peerings = map(object({
      name        = string
      remote_peer = bool
    }))

    subnets = map(object({
      name             = string
      address_prefixes = list(string)
      delegation       = optional(list(string))
    }))

    route_tables = map(object({
      name = string

      routes = map(object({
        name                   = string
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = string
      }))
    }))
  }))
}

variable "virtual_networks_dns_servers" {
  type = list(string)
}

variable "sentinel_workspace" {
  type = map(object({
    name     = string
    location = string
    sku      = string
  }))
}

variable "azure_virtual_desktop" {
  type = map(object({
    name                                   = string
    location                               = string
    type                                   = string
    load_balancer_type                     = string
    maximum_sessions_allowed               = number
    description                            = string
    start_vm_on_connect                    = bool
    domain_name                            = string
    domain_ou_path                         = string
    domain_restart                         = bool
    host_pool_registration_expiration_date = string
    computer_name                          = string
    sku                                    = string
    instances                              = string
    image_publisher                        = string
    image_offer                            = string
    image_sku                              = string
    image_version                          = string
    license_type                           = string
    #virtual_machine_scale_set = map(object({
    #  name                 = string
    #  sku                  = string
    #  instances            = number
    #  computer_name_prefix = string
    #  image_publisher      = string
    #  image_offer          = string
    #  image_sku            = string
    #  image_version        = string
    #  license_type         = string
    #}))
    #storage_account = map(object({
    #  name                     = string
    #  account_tier             = string
    #  account_replication_type = string
    #  account_kind             = string
    #  storage_share_name       = string
    #}))
  }))
}
