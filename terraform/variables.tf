variable "environment" {
  description = "Environment name (platform or workload)"
  type        = string
  validation {
    condition     = contains(["platform", "workload"], var.environment)
    error_message = "Environment must be either 'platform' or 'workload'."
  }
}

variable "region" {
  description = "Azure region for deployments"
  type        = string
  default     = "westeurope"
}

variable "location_code" {
  description = "Location code for naming convention (e.g., 'we' for West Europe)"
  type        = string
  default     = "we"
}

variable "organization_name" {
  description = "Organization name for naming convention"
  type        = string
  default     = "slz"
}

variable "platform_subscription_id" {
  description = "Platform landing zone subscription ID"
  type        = string
  sensitive   = true
}

variable "workload_subscription_ids" {
  description = "Map of workload subscription IDs by name"
  type        = map(string)
  sensitive   = true
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "SLZ"
  }
}

# SLZ-specific variables for sovereignty controls
variable "enable_customer_managed_keys" {
  description = "Enable customer managed keys for encryption"
  type        = bool
  default     = true
}

variable "enable_confidential_computing" {
  description = "Enable confidential computing for sensitive workloads"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Enable comprehensive audit logging for compliance"
  type        = bool
  default     = true
}

variable "data_residency_region" {
  description = "Region where data must reside (e.g., 'EU' for European Union)"
  type        = string
  default     = "EU"
}
