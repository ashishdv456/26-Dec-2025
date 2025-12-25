terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.44.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0a2d6fb2-0cdf-4ef1-bc96-b60d4c91cfb4"
}