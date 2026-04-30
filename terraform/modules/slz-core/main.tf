terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "organization_name" {
  type = string
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "client_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "enable_customer_managed_keys" {
  type    = bool
  default = true
}

variable "enable_confidential_computing" {
  type    = bool
  default = true
}

variable "enable_audit_logging" {
  type    = bool
  default = true
}

variable "data_residency_region" {
  type    = string
  default = "EU"
}

variable "tags" {
  type = map(string)
}

locals {
  key_vault_name = "${replace(var.resource_prefix, "-", "")}${var.environment}kv"
}

# Key Vault for customer managed keys (CMK)
resource "azurerm_key_vault" "slz" {
  count = var.enable_customer_managed_keys ? 1 : 0

  name                = substr(local.key_vault_name, 0, 24)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "premium"

  enabled_for_disk_encryption       = true
  enabled_for_deployment            = true
  enabled_for_template_deployment   = true
  purge_protection_enabled          = true
  soft_delete_retention_days        = 90
  enable_rbac_authorization         = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = []
  }

  tags = var.tags
}

# Storage account for audit logs with customer managed encryption
resource "azurerm_storage_account" "audit_logs" {
  count = var.enable_audit_logging ? 1 : 0

  name                     = "${replace(var.resource_prefix, "-", "")}auditlog"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  infrastructure_encryption_enabled = true
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = []
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}

# Storage container for logs
resource "azurerm_storage_container" "audit_logs" {
  count = var.enable_audit_logging ? 1 : 0

  name                  = "audit-logs"
  storage_account_name  = azurerm_storage_account.audit_logs[0].name
  container_access_type = "private"
}

# Log Analytics Workspace for compliance and monitoring
resource "azurerm_log_analytics_workspace" "slz" {
  count = var.enable_audit_logging ? 1 : 0

  name                = "${var.resource_prefix}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 730 # 2 years for compliance

  daily_quota_gb = -1 # Unlimited

  tags = var.tags
}

# Diagnostic setting for subscription-level audit logs
resource "azurerm_monitor_diagnostic_setting" "slz_audit" {
  count = var.enable_audit_logging ? 1 : 0

  name               = "${var.resource_prefix}-audit-diagnostics"
  target_resource_id = "/subscriptions/${var.subscription_id}"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.slz[0].id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  depends_on = [azurerm_log_analytics_workspace.slz]
}

# Outputs
output "key_vault_id" {
  value = try(azurerm_key_vault.slz[0].id, null)
}

output "key_vault_name" {
  value = try(azurerm_key_vault.slz[0].name, null)
}

output "storage_account_id" {
  value = try(azurerm_storage_account.audit_logs[0].id, null)
}

output "log_analytics_workspace_id" {
  value = try(azurerm_log_analytics_workspace.slz[0].id, null)
}

output "log_analytics_workspace_name" {
  value = try(azurerm_log_analytics_workspace.slz[0].name, null)
}
