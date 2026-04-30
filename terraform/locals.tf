locals {
  # Naming convention
  resource_prefix = "${var.organization_name}-${var.location_code}"

  # Common resource naming
  rg_name = "${local.resource_prefix}-${var.environment}-rg"

  # Tags to apply to all resources
  common_tags = merge(
    var.tags,
    {
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
      Region      = var.region
      Environment = var.environment
    }
  )

  # Subscription context
  platform_subscription_id = var.platform_subscription_id
  workload_subscriptions   = var.workload_subscription_ids

  # SLZ configuration
  slz_settings = {
    customer_managed_keys     = var.enable_customer_managed_keys
    confidential_computing    = var.enable_confidential_computing
    audit_logging             = var.enable_audit_logging
    data_residency_region     = var.data_residency_region
  }
}
