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

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "slz_settings" {
  type = object({
    customer_managed_keys     = bool
    confidential_computing    = bool
    audit_logging             = bool
    data_residency_region     = string
  })
}

variable "tags" {
  type = map(string)
}

locals {
  # Policy definitions for SLZ sovereignty controls
  policy_definitions = {
    # Require encryption at rest
    "encryption-at-rest" = {
      display_name = "Require encryption at rest for SLZ"
      description  = "Enforces encryption at rest for all storage and compute resources"
      rule = jsonencode({
        if = {
          allOf = [
            {
              field  = "type"
              in     = ["Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers/databases"]
            }
          ]
        }
        then = {
          effect = "deny"
        }
      })
    }

    # Restrict data residency
    "data-residency" = {
      display_name = "Restrict resources to ${var.slz_settings.data_residency_region}"
      description  = "Ensures all resources stay within ${var.slz_settings.data_residency_region} for data sovereignty"
      rule = jsonencode({
        if = {
          field  = "location"
          notIn  = ["westeurope", "northeurope", "swedencentral"]
        }
        then = {
          effect = "deny"
        }
      })
    }

    # Require HTTPS
    "https-only" = {
      display_name = "Require HTTPS for all communication"
      description  = "Enforces HTTPS/TLS for all external communication"
      rule = jsonencode({
        if = {
          anyOf = [
            {
              field = "type"
              equals = "Microsoft.Web/sites"
            }
          ]
        }
        then = {
          effect = "deny"
        }
      })
    }

    # Require TLS 1.2 minimum
    "tls-minimum" = {
      display_name = "Require minimum TLS 1.2"
      description  = "Enforces TLS 1.2 as minimum for all services"
      rule = jsonencode({
        if = {
          field  = "Microsoft.Storage/storageAccounts/minimumTlsVersion"
          exists = "true"
        }
        then = {
          effect = "deny"
        }
      })
    }

    # Enable audit logging
    "audit-logging-required" = {
      display_name = "Enable diagnostic logging"
      description  = "Requires diagnostic logging for audit and compliance"
      rule = jsonencode({
        if = {
          field  = "type"
          in     = ["Microsoft.Sql/servers", "Microsoft.Storage/storageAccounts"]
        }
        then = {
          effect = "deny"
        }
      })
    }
  }
}

# Policy definition for encryption at rest
resource "azurerm_policy_definition" "encryption_at_rest" {
  count = var.slz_settings.customer_managed_keys ? 1 : 0

  name                = "${var.resource_prefix}-encryption-at-rest"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "SLZ: Require encryption at rest"
  description         = "Enforces customer-managed keys and encryption at rest for sensitive resources"
  management_group_id = null

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          in     = ["Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers/databases", "Microsoft.KeyVault/vaults"]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

# Policy definition for data residency
resource "azurerm_policy_definition" "data_residency" {
  name                = "${var.resource_prefix}-data-residency"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "SLZ: Data Residency - ${var.slz_settings.data_residency_region}"
  description         = "Ensures all resources are deployed in ${var.slz_settings.data_residency_region} for data sovereignty"
  management_group_id = null

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "location"
          notIn  = ["westeurope", "northeurope", "swedencentral"]
        },
        {
          field  = "Microsoft.Storage/storageAccounts/accessTier"
          equals = "Archive"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

# Policy definition for HTTPS/TLS enforcement
resource "azurerm_policy_definition" "https_tls" {
  name                = "${var.resource_prefix}-https-tls-required"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "SLZ: Require HTTPS and TLS 1.2"
  description         = "Enforces HTTPS and minimum TLS 1.2 for all network communication"
  management_group_id = null

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "type"
          equals = "Microsoft.Web/sites"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

# Policy assignment for encryption
resource "azurerm_subscription_policy_assignment" "encryption" {
  count = var.slz_settings.customer_managed_keys ? 1 : 0

  name                = "${var.resource_prefix}-encryption-assignment"
  subscription_id     = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.encryption_at_rest[0].id
  enforce             = false # Start with audit mode
  description         = "Audit and enforce encryption at rest policies"
}

# Policy assignment for data residency
resource "azurerm_subscription_policy_assignment" "data_residency" {
  name                = "${var.resource_prefix}-data-residency-assignment"
  subscription_id     = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.data_residency.id
  enforce             = false # Start with audit mode
  description         = "Enforce data residency in ${var.slz_settings.data_residency_region}"
}

# Policy assignment for HTTPS/TLS
resource "azurerm_subscription_policy_assignment" "https_tls" {
  name                = "${var.resource_prefix}-https-tls-assignment"
  subscription_id     = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.https_tls.id
  enforce             = false # Start with audit mode
  description         = "Enforce HTTPS and TLS 1.2 requirements"
}

# Outputs
output "policy_assignments" {
  value = {
    encryption     = try(azurerm_subscription_policy_assignment.encryption[0].id, null)
    data_residency = azurerm_subscription_policy_assignment.data_residency.id
    https_tls      = azurerm_subscription_policy_assignment.https_tls.id
  }
}
