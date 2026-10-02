variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where network resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region where network resources will be created."
}