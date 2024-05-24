terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.92.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

variable "location" {
  type        = string
  default     = "northeurope"
  description = "Resource groups location"
}

resource "azurerm_resource_group" "simple_server_app" {
  name     = "rg-simple-server-app-ne-001"
  location = var.location
}
