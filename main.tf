terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "codealpha-tfstate"
    storage_account_name = "codealphasa"
    container_name       = "codealpastatetf"
    key                  = "codealpha.tfstate"
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  suffix   = random_string.suffix.result
  acr_name = "${var.prefix}acr${local.suffix}"
  app_name = "${var.prefix}-app-${local.suffix}"
  pg_name  = "${var.prefix}-pg-${local.suffix}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_postgresql_flexible_server" "pg" {
  name                          = local.pg_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  administrator_login           = var.pg_admin
  administrator_password        = var.pg_password
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = "32768"
  public_network_access_enabled = true

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.pg.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
}

resource "azurerm_linux_web_app" "app" {
  name                = local.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  site_config {
    always_on = true

    application_stack {
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_image_name        = "${var.image_name}:latest"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password

    }
  }

  app_settings = {
    WEBSITES_PORT                       = var.app_port
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DB_HOST                             = azurerm_postgresql_flexible_server.pg.fqdn
    DB_PORT                             = "5432"
    DB_USER                             = var.admin_user
    DB_PASSWORD                         = var.admin_password
    DB_NAME                             = var.db_name
    PGSSLMODE                           = "required"
  }

  lifecycle {
    ignore_changes = [site_config[0].application_stack[0].docker_image_name]
  }

}
