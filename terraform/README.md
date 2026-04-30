# Sovereign Landing Zone (SLZ) - Terraform Configuration

This directory contains the Terraform configuration for deploying a Sovereign Landing Zone on Azure.

## 📁 Directory Structure

```
terraform/
├── versions.tf              # Provider configuration and requirements
├── variables.tf             # Input variables
├── locals.tf                # Local values and naming conventions
├── main.tf                  # Main resource definitions
├── outputs.tf               # Output values
├── .gitignore               # Git ignore for sensitive files
│
├── modules/
│   ├── slz-core/           # Core SLZ resources (Key Vault, Storage, Logs)
│   │   └── main.tf
│   └── slz-policies/       # Azure Policies for sovereignty controls
│       └── main.tf
│
└── environments/
    ├── platform/           # Platform landing zone configuration
    │   └── terraform.tfvars
    └── workload/           # Workload subscription configuration
        └── terraform.tfvars
```

## 🎯 Key Resources Deployed

### Platform Landing Zone
- **Resource Group**: Central management and governance
- **Azure Key Vault** (Premium): For encryption key management
- **Storage Account**: Audit log storage with GRS redundancy
- **Log Analytics Workspace**: 730-day audit retention
- **Azure Policies**: Enforce SLZ sovereignty controls

### Sovereignty Controls
1. **Data Residency**: Restrict to EU regions
2. **Encryption**: Customer-managed keys (CMK)
3. **Audit Logging**: Comprehensive diagnostic logging
4. **Network Security**: TLS 1.2+ enforcement
5. **Confidential Computing**: Support for secure enclaves

## 🚀 Quick Start

### 1. Configure Your Subscriptions
Edit the `terraform.tfvars` files:

```bash
# Platform environment
nano environments/platform/terraform.tfvars

# Workload environment  
nano environments/workload/terraform.tfvars
```

Update the subscription IDs with your actual Azure subscription IDs:
```hcl
platform_subscription_id = "YOUR-PLATFORM-SUBSCRIPTION-ID"
workload_subscription_ids = {
  workload1 = "YOUR-WORKLOAD-1-SUBSCRIPTION-ID"
  workload2 = "YOUR-WORKLOAD-2-SUBSCRIPTION-ID"
}
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Plan the Deployment
```bash
terraform plan \
  -var-file="environments/platform/terraform.tfvars" \
  -var="platform_subscription_id=YOUR-SUBSCRIPTION-ID" \
  -var="workload_subscription_ids={workload1=\"SUB-ID-1\",workload2=\"SUB-ID-2\"}"
```

### 4. Apply the Configuration
```bash
terraform apply tfplan.binary
```

## 🔧 Configuration Options

### Enable/Disable SLZ Features

Edit `terraform.tfvars` to enable or disable features:

```hcl
# Encryption
enable_customer_managed_keys = true

# Confidential computing support
enable_confidential_computing = true

# Audit and compliance logging
enable_audit_logging = true

# Data residency enforcement
data_residency_region = "EU"
```

## 🔐 Security Best Practices

1. **Key Vault Access**
   - Use RBAC for access management
   - Enable purge protection
   - Audit all key access

2. **Encryption Keys**
   - Rotate CMK regularly
   - Monitor key usage
   - Implement backup/recovery

3. **Audit Logs**
   - Review logs regularly
   - Set up alerts for security events
   - Archive logs for compliance

4. **Policy Compliance**
   - Start with audit mode (non-blocking)
   - Monitor compliance in Log Analytics
   - Transition to enforce mode

## 📊 Managing Deployments

### View Current State
```bash
terraform state list
terraform state show <resource>
```

### Update Configuration
```bash
# Edit terraform.tfvars or variables
terraform plan -var-file="environments/platform/terraform.tfvars"
terraform apply tfplan.binary
```

### Destroy Resources (Use Caution!)
```bash
terraform destroy -var-file="environments/platform/terraform.tfvars"
```

## 🔄 GitOps Workflow

This configuration is designed for automated deployment via GitHub Actions:

1. **Commit changes** to Terraform files
2. **Push to main** branch
3. **GitHub Actions** automatically:
   - Runs `terraform plan`
   - Creates artifacts
   - Applies on merge/push
   - Publishes deployment summary

## 📚 Module Documentation

### slz-core
Creates core SLZ infrastructure:
- Azure Key Vault (CMK storage)
- Storage Account (audit logs)
- Log Analytics Workspace
- Diagnostic settings

**Inputs:**
- `resource_group_name`: Target resource group
- `location`: Azure region
- `enable_customer_managed_keys`: Enable CMK
- `enable_audit_logging`: Enable logging

**Outputs:**
- `key_vault_id`: Key Vault resource ID
- `storage_account_id`: Storage account ID
- `log_analytics_workspace_id`: LAW resource ID

### slz-policies
Defines and assigns Azure Policies:
- Data residency enforcement
- Encryption requirements
- TLS/HTTPS enforcement
- Audit logging requirements

**Inputs:**
- `subscription_id`: Target subscription
- `slz_settings`: Sovereignty configuration

**Outputs:**
- `policy_assignments`: Policy assignment IDs

## 🆘 Troubleshooting

### Terraform State Conflicts
```bash
# Refresh state
terraform refresh

# Remove local state
rm -rf .terraform/
terraform init
```

### Authentication Errors
```bash
# Login to Azure
az login
az account set --subscription <SUBSCRIPTION_ID>

# Verify permissions
az role assignment list --scope /subscriptions/<SUB_ID>
```

### Policy Application Issues
```bash
# Check policy compliance status
az policy assignment list --output table
az policy state list --resource-group <RG_NAME>
```

## 🎓 Learning Resources

- [Azure Landing Zone Documentation](https://azure.github.io/Azure-Landing-Zones/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure Policies for Sovereignty](https://learn.microsoft.com/en-us/azure/azure-sovereign-clouds/public/)
- [Azure Security Best Practices](https://learn.microsoft.com/en-us/azure/security/)

## 📝 Notes

- Terraform state files contain sensitive information - **do not commit** to Git
- Key Vault requires purge protection disabled after deletion for re-creation
- Log retention is set to 730 days for compliance (adjust as needed)
- Policy enforcement starts in audit mode for validation

---

**For detailed deployment instructions, see [SLZ-DEPLOYMENT-GUIDE.md](../SLZ-DEPLOYMENT-GUIDE.md)**
