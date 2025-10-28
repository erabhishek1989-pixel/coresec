variable "rgname" {
  description = "Name of the resource group"
  type        = string
}

variable "rglocation" {
  description = "Location of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(any)
}

variable "environment_identifier" {
  type = string
}
