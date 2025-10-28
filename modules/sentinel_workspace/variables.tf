variable "name" {
  type = string
}

variable "environment_identifier" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(any)
}

variable "sku" {
  type = string
}

variable "resource_group_name" {
  type = string
}

# NEW: Add these variables
variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "workspace_shared_key_secret_uri" {
  description = "Key Vault secret URI for workspace shared key"
  type        = string
  default     = null
}

variable "application_insights_key" {
  description = "Application Insights key"
  type        = string
  default     = null
}

variable "connectors" {
  description = "Map of data connectors"
  type = map(object({
    enabled                  = bool
    connector_type           = string
    key_vault_name           = optional(string)
    key_vault_resource_group = optional(string)
    endpoint                 = optional(string)
    secrets                  = optional(map(string))
    config                   = optional(map(any))
  }))
  default = {}
}
