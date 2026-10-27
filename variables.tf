variable "subscription_id" {
  type        = string
  description = "The subscription ID for provider"
  default     = "f0679c99-0d63-422d-93ae-ec929728065c"
}

variable "location" {
  type        = string
  description = "The loction for the resource group"
  default     = "southafricanorth"
}

variable "azurerm_resource_group_name" {
  type        = string
  description = "The name of the resource group"
  default     = "codealpha-simple-notes-app"
}

variable "prefix" {
  type        = string
  description = "The prefix for the resourcea"
  default     = "codealpha"
}

variable "image_name" {
  type        = string
  description = "The name of the image to be used for the container"
  default     = "codealpha-simple-notes-app"
}

variable "app_port" {
  type        = string
  description = "The port on which the application will run"
  default     = "3000"
}

variable "app_service_sku" {
  type        = string
  description = "The SKU for the app service plan"
  default     = "B1"
}

variable "admin_user" {
  type        = string
  description = "The admin user for the database"
  default     = "codealpha"
}

variable "admin_password" {
  type        = string
  description = "The admin password for the database"
  sensitive   = true
  default     = "codealpha123@"
}
variable "db_name" {
  type        = string
  description = "The name of the databse"
  default     = "codealpha-db"
}

variable "pg_admin" {
  type        = string
  description = "The administrator login for the database"
  default     = "codealpha"
}

variable "pg_password" {
  type        = string
  description = "The administator password for the database"
  sensitive   = true
  default     = "codealpha123@"
}

