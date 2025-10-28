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
