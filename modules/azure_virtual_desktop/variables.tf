variable "environment_identifier" {
  type = string
}

variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(any)
}

variable "location" {
  type = string
}

variable "type" {
  type = string
}

variable "load_balancer_type" {
  type = string
}

variable "maximum_sessions_allowed" {
  type = number
}

variable "description" {
  type = string
}

variable "start_vm_on_connect" {
  type = string
}

variable "host_pool_registration_expiration_date" {
  type = string
}

variable "secret_admin_username" {
  type = string
}

variable "secret_admin_password" {
  type = string
}

variable "secret_res_ads_username" {
  type = string
}

variable "secret_res_ads_password" {
  type = string
}
variable "domain_name" {
  type = string
}

variable "domain_ou_path" {
  type = string
}

variable "domain_restart" {
  type = bool
}

variable "subnet_id" {
  type = string
}

variable "computer_name" {
  type = string
}

variable "sku" {
  type = string
}

variable "instances" {
  type = string
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "image_version" {
  type = string
}

variable "license_type" {
  type = string
}

#variable "virtual_machine_scale_set" {
#  type = map(object({
#    name                 = string
#    sku                  = string
#    instances            = number
#    computer_name_prefix = string
#    image_publisher      = string
#    image_offer          = string
#    image_sku            = string
#    image_version        = string
#    license_type         = string
#  }))
#}
#
#variable "storage_account" {
#  type = map(object({
#    name                     = string
#    account_tier             = string
#    account_replication_type = string
#    account_kind             = string
#    storage_share_name       = string
#  }))
#}
