output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.slz.id
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.slz.name
}

output "location" {
  description = "Azure region for deployments"
  value       = azurerm_resource_group.slz.location
}

output "environment" {
  description = "Environment type (platform or workload)"
  value       = var.environment
}

output "platform_outputs" {
  description = "Outputs from platform landing zone module"
  value       = try(module.slz_platform[0], null)
  sensitive   = true
}

output "workload_outputs" {
  description = "Outputs from workload module"
  value       = try(module.slz_workload[0], null)
  sensitive   = true
}

output "slz_configuration" {
  description = "SLZ sovereignty configuration"
  value = {
    customer_managed_keys     = var.enable_customer_managed_keys
    confidential_computing    = var.enable_confidential_computing
    audit_logging             = var.enable_audit_logging
    data_residency_region     = var.data_residency_region
  }
}
