variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where VM scheduler resources will be deployed."
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where VM scheduler resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region where VM scheduler resources will be created."
}
