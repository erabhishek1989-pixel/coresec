variable "function_app_name" {
  description = "Function app name"
  type        = string
}

variable "service_plan_name" {
  description = "App service plan name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for function app"
  type        = string
}

variable "storage_account_access_key" {
  description = "Storage account access key"
  type        = string
  sensitive   = true
}

variable "os_type" {
  description = "OS type"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "SKU name for app service plan"
  type        = string
  default     = "Y1"
}

variable "python_version" {
  description = "Python version"
  type        = string
  default     = "3.9"
}

variable "app_settings" {
  description = "App settings for function app"
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for access policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(any)
}