data "azurerm_client_config" "current" {}

# Select subscription based on environment
terraform {
  dynamic "cloud" {
    for_each = [] # Placeholder for future cloud config
  }
}

# Resource group for SLZ
resource "azurerm_resource_group" "slz" {
  name       = local.rg_name
  location   = var.region
  tags       = local.common_tags
}

# Platform Landing Zone Module
module "slz_platform" {
  count = var.environment == "platform" ? 1 : 0

  source = "./modules/slz-core"

  resource_group_name       = azurerm_resource_group.slz.name
  resource_group_id         = azurerm_resource_group.slz.id
  location                  = azurerm_resource_group.slz.location
  environment               = var.environment
  resource_prefix           = local.resource_prefix
  organization_name         = var.organization_name
  subscription_id           = data.azurerm_client_config.current.subscription_id
  client_id                 = data.azurerm_client_config.current.client_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id

  # SLZ sovereignty controls
  enable_customer_managed_keys = var.enable_customer_managed_keys
  enable_confidential_computing = var.enable_confidential_computing
  enable_audit_logging         = var.enable_audit_logging
  data_residency_region        = var.data_residency_region

  tags = local.common_tags
}

# SLZ Policies Module for sovereignty enforcement
module "slz_policies" {
  count = var.environment == "platform" ? 1 : 0

  source = "./modules/slz-policies"

  resource_group_name = azurerm_resource_group.slz.name
  location            = azurerm_resource_group.slz.location
  environment         = var.environment
  resource_prefix     = local.resource_prefix
  subscription_id     = data.azurerm_client_config.current.subscription_id

  # SLZ settings
  slz_settings = local.slz_settings

  tags = local.common_tags

  depends_on = [module.slz_platform]
}

# Workload subscription configuration
module "slz_workload" {
  count = var.environment == "workload" ? 1 : 0

  source = "./modules/slz-core"

  resource_group_name       = azurerm_resource_group.slz.name
  resource_group_id         = azurerm_resource_group.slz.id
  location                  = azurerm_resource_group.slz.location
  environment               = var.environment
  resource_prefix           = local.resource_prefix
  organization_name         = var.organization_name
  subscription_id           = data.azurerm_client_config.current.subscription_id
  client_id                 = data.azurerm_client_config.current.client_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id

  # SLZ sovereignty controls
  enable_customer_managed_keys = var.enable_customer_managed_keys
  enable_confidential_computing = var.enable_confidential_computing
  enable_audit_logging         = var.enable_audit_logging
  data_residency_region        = var.data_residency_region

  tags = local.common_tags
}
