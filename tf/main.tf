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

resource "azurerm_log_analytics_workspace" "simple_server_app_log" {
  name                = "log-simple-server-app-ne-001"
  location            = azurerm_resource_group.simple_server_app.location
  resource_group_name = azurerm_resource_group.simple_server_app.name
}

resource "azurerm_container_app_environment" "simple_server_container_app_env" {
  name                       = "container-app-simple-server-app-ne-001"
  location                   = azurerm_resource_group.simple_server_app.location
  resource_group_name        = azurerm_resource_group.simple_server_app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.simple_server_app_log.id
}

variable "docker_secrets" {
  type = object({
    name = string
    user = string
    pass = string
  })
}

resource "azurerm_container_app" "simple_server_app_dockerhub" {
  name                         = "simple-server-app-dh-ne-001"
  container_app_environment_id = azurerm_container_app_environment.simple_server_container_app_env.id
  resource_group_name          = azurerm_resource_group.simple_server_app.name
  revision_mode                = "Single"

  registry {
    server               = "docker.io"
    username             = var.docker_secrets.user
    password_secret_name = var.docker_secrets.name
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "simple-serv-app-dh-container"
      image  = "asutptec4/shop-simple-serv-app:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONTAINER_REGISTRY_NAME"
        value = "Docker Hub"
      }
    }
  }

  secret {
    name  = var.docker_secrets.name
    value = var.docker_secrets.pass
  }
}

resource "azurerm_container_registry" "simple_server_app_container_regestry" {
  name                = "simpleserverappacrne001"
  resource_group_name = azurerm_resource_group.simple_server_app.name
  location            = azurerm_resource_group.simple_server_app.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app" "simple_server_app_azure_registry" {
  name                         = "simple-server-app-acr-ne-001"
  container_app_environment_id = azurerm_container_app_environment.simple_server_container_app_env.id
  resource_group_name          = azurerm_resource_group.simple_server_app.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.simple_server_app_container_regestry.login_server
    username             = azurerm_container_registry.simple_server_app_container_regestry.admin_username
    password_secret_name = "acr-password"
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

  }

  template {
    container {
      name   = "simple-serv-app-acr-container"
      image  = "${azurerm_container_registry.simple_server_app_container_regestry.login_server}/shop-simple-serv-app:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONTAINER_REGISTRY_NAME"
        value = "Azure Container Registry"
      }
    }
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.simple_server_app_container_regestry.admin_password
  }
}
