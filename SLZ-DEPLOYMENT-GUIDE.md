# Sovereign Landing Zone (SLZ) Deployment Guide

## 📋 Prerequisites

Before deploying your Sovereign Landing Zone, ensure you have:

1. **Azure Subscription(s)**
   - 1 Platform subscription (management/governance)
   - 2 Workload subscriptions (business applications)
   - Subscription IDs noted for configuration

2. **Local Environment**
   - Terraform >= 1.5.0
   - Azure CLI (az command)
   - PowerShell or Bash shell
   - Git

3. **Azure Permissions**
   - Owner or Contributor role at subscription level
   - Ability to create service principals
   - Ability to assign Azure AD roles

4. **GitHub Setup**
   - GitHub repository with Actions enabled
   - Permissions to create secrets and environments

## 🔧 Step 1: Configure Subscription IDs

Edit the Terraform variable files with your actual Azure subscription IDs:

### Platform Environment
```bash
# Edit: terraform/environments/platform/terraform.tfvars
platform_subscription_id = "YOUR-PLATFORM-SUB-ID-HERE"
workload_subscription_ids = {
  workload1 = "YOUR-WORKLOAD-SUB-1-ID-HERE"
  workload2 = "YOUR-WORKLOAD-SUB-2-ID-HERE"
}
```

### Workload Environment
```bash
# Edit: terraform/environments/workload/terraform.tfvars
# Use the same subscription IDs as above
```

## 🔐 Step 2: Set Up Azure Service Principal for GitHub Actions

Create a service principal for GitHub Actions OIDC authentication:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-slz-deployment" \
  --role Contributor \
  --scopes /subscriptions/{PLATFORM_SUB_ID} \
              /subscriptions/{WORKLOAD_SUB_1_ID} \
              /subscriptions/{WORKLOAD_SUB_2_ID}

# Save the output - you'll need these values
```

Then set up OIDC trust:

```bash
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters @credential.json
```

**credential.json:**
```json
{
  "name": "github-slz",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:nkalayci/nkalayci.github.io:ref:refs/heads/main",
  "description": "SLZ GitHub Actions deployment",
  "audiences": ["api://AzureADTokenExchange"]
}
```

## 🔑 Step 3: Add GitHub Secrets

In your GitHub repository, add the following secrets:

**Settings → Secrets and variables → Actions:**

- `AZURE_CLIENT_ID`: The client ID from your service principal
- `AZURE_TENANT_ID`: Your Azure tenant ID
- `AZURE_SUBSCRIPTION_ID_PLATFORM`: Your platform subscription ID
- `AZURE_SUBSCRIPTION_ID_WORKLOAD1`: Your first workload subscription ID
- `AZURE_SUBSCRIPTION_ID_WORKLOAD2`: Your second workload subscription ID

## 📦 Step 4: Initialize Terraform Locally (Optional)

To test locally before pushing to GitHub:

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan \
  -var-file="environments/platform/terraform.tfvars" \
  -var="platform_subscription_id=YOUR-PLATFORM-SUB-ID" \
  -var="workload_subscription_ids={workload1=\"SUB-ID-1\",workload2=\"SUB-ID-2\"}"
```

## 🚀 Step 5: Deploy SLZ

### Option A: Automatic Deployment (GitHub Actions)

1. Commit your changes:
```bash
git add terraform/ .github/
git commit -m "Add SLZ deployment configuration"
git push origin main
```

2. GitHub Actions will automatically:
   - Run Terraform plan
   - Create artifacts
   - Deploy to Azure (on main branch)

3. Monitor the workflow in GitHub → Actions

### Option B: Manual Deployment

```bash
cd terraform

# Login to Azure
az login
az account set --subscription "YOUR-PLATFORM-SUB-ID"

# Apply configuration
terraform apply \
  -var-file="environments/platform/terraform.tfvars" \
  -var="platform_subscription_id=YOUR-PLATFORM-SUB-ID" \
  -var="workload_subscription_ids={workload1=\"SUB-ID-1\",workload2=\"SUB-ID-2\"}"

# For workload deployment
az account set --subscription "YOUR-WORKLOAD-SUB-1-ID"
terraform apply \
  -var-file="environments/workload/terraform.tfvars" \
  -var="platform_subscription_id=YOUR-PLATFORM-SUB-ID" \
  -var="workload_subscription_ids={workload1=\"SUB-ID-1\",workload2=\"SUB-ID-2\"}"
```

## 🛡️ SLZ Sovereignty Controls Deployed

Your deployment includes:

### 1. **Data Residency**
   - Resources restricted to EU regions (westeurope, northeurope, swedencentral)
   - Policy enforcement for data sovereignty

### 2. **Encryption**
   - Customer-managed encryption keys (CMK) in Azure Key Vault
   - Infrastructure encryption enabled
   - TLS 1.2+ enforcement

### 3. **Audit & Compliance**
   - Log Analytics Workspace (730 days retention)
   - Storage accounts for audit logs
   - Diagnostic settings for subscription-level logging
   - Administrative, Security, and ServiceHealth categories

### 4. **Confidential Computing**
   - Support for confidential VMs and containers
   - Secure enclaves for sensitive workloads

## 📊 Monitoring & Validation

### Check Policy Assignments
```bash
az policy assignment list --scope /subscriptions/{SUBSCRIPTION_ID}
```

### View Audit Logs
```bash
# In Azure Portal:
# 1. Go to your Log Analytics Workspace
# 2. Run KQL queries for audit events
# 3. Monitor compliance with SLZ policies
```

### Terraform Outputs
```bash
terraform output

# Example output:
# resource_group_id = "/subscriptions/.../resourceGroups/slz-we-platform-rg"
# key_vault_id = "/subscriptions/.../Microsoft.KeyVault/vaults/slzweplatformkv"
# log_analytics_workspace_id = "..."
```

## 🔄 Updating Your Deployment

To modify SLZ configuration:

1. Edit `terraform.tfvars` files
2. Test locally with `terraform plan`
3. Commit and push changes
4. GitHub Actions will handle the deployment

```bash
# Example: Enable confidential computing
# Edit: terraform/environments/platform/terraform.tfvars
enable_confidential_computing = true

git commit -am "Enable confidential computing for SLZ"
git push
```

## ⚠️ Important Notes

### State Management
- Local state is used by default (`.terraform/`)
- For production, consider enabling remote state in Azure Storage
- Uncomment the `backend` configuration in `terraform/versions.tf`

### Policy Enforcement
- Policies start in **audit mode** (non-blocking)
- Monitor audit logs before switching to **enforce mode**
- Update policy assignments to set `enforce = true`

### Cost Considerations
- Key Vault Premium tier: ~$11/month per vault
- Log Analytics: Data ingestion charges apply
- Storage accounts: Standard GRS redundancy
- Estimate costs using [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

## 🆘 Troubleshooting

### Terraform Validation Fails
```bash
# Check for configuration errors
terraform validate
terraform fmt -check -recursive
```

### Authentication Issues
```bash
# Verify Azure CLI login
az account show

# Check service principal permissions
az role assignment list --scope /subscriptions/{SUBSCRIPTION_ID}
```

### Policy Application Issues
```bash
# Review policy assignment status
az policy assignment list --query "[].{Name:name, Status:enforcement_mode}"
```

### GitHub Actions Secrets Not Found
- Verify secret names match exactly (case-sensitive)
- Check secrets are added to the correct repository
- Verify workflow has `id-token: write` permission

## 📚 Additional Resources

- [Azure Landing Zone Documentation](https://azure.github.io/Azure-Landing-Zones/)
- [Sovereign Landing Zone (SLZ) Overview](https://learn.microsoft.com/en-us/azure/azure-sovereign-clouds/public/overview-sovereign-landing-zone)
- [Azure Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🎯 Next Steps

1. ✅ Configure subscription IDs
2. ✅ Create Azure service principal
3. ✅ Add GitHub secrets
4. ✅ Validate Terraform locally
5. ✅ Commit and deploy via GitHub Actions
6. ✅ Monitor deployment in Azure Portal
7. ✅ Review audit logs in Log Analytics
8. ✅ Customize policies as needed

---

**Need Help?**
- Check [GitHub Issues](../../issues)
- Review workflow logs in GitHub Actions
- Consult [Azure Support](https://support.microsoft.com/en-us/contactus)
