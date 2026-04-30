#!/bin/bash
# SLZ Quick Deployment Script
# This script helps you quickly deploy your Sovereign Landing Zone

set -e

echo "🚀 Sovereign Landing Zone (SLZ) Deployment Script"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check Terraform
if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install Terraform 1.5.0 or later."
    exit 1
fi
print_status "Terraform $(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4) installed"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install Azure CLI."
    exit 1
fi
print_status "Azure CLI installed"

# Check Git
if ! command -v git &> /dev/null; then
    print_error "Git not found. Please install Git."
    exit 1
fi
print_status "Git installed"

echo ""
echo "Prerequisites check completed!"
echo ""

# Get subscription IDs
echo "Please provide your Azure subscription IDs:"
read -p "Platform Subscription ID: " PLATFORM_SUB
read -p "Workload 1 Subscription ID: " WORKLOAD_SUB1
read -p "Workload 2 Subscription ID: " WORKLOAD_SUB2

# Validate subscription IDs (basic format check)
if [[ ! $PLATFORM_SUB =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    print_error "Invalid Platform subscription ID format"
    exit 1
fi

echo ""
echo "Updating Terraform configuration files..."

# Update platform terraform.tfvars
cat > terraform/environments/platform/terraform.tfvars << EOF
environment            = "platform"
region                 = "westeurope"
location_code          = "we"
organization_name      = "slz"

platform_subscription_id = "$PLATFORM_SUB"

workload_subscription_ids = {
  workload1 = "$WORKLOAD_SUB1"
  workload2 = "$WORKLOAD_SUB2"
}

enable_customer_managed_keys = true
enable_confidential_computing = true
enable_audit_logging = true
data_residency_region = "EU"

tags = {
  Environment = "Production"
  Project     = "SLZ"
  CostCenter  = "Platform"
  Owner       = "Platform Engineering"
}
EOF

# Update workload terraform.tfvars
cat > terraform/environments/workload/terraform.tfvars << EOF
environment            = "workload"
region                 = "westeurope"
location_code          = "we"
organization_name      = "slz"

platform_subscription_id = "$PLATFORM_SUB"

workload_subscription_ids = {
  workload1 = "$WORKLOAD_SUB1"
  workload2 = "$WORKLOAD_SUB2"
}

enable_customer_managed_keys = true
enable_confidential_computing = true
enable_audit_logging = true
data_residency_region = "EU"

tags = {
  Environment = "Production"
  Project     = "SLZ"
  CostCenter  = "Workload"
  Owner       = "Workload Team"
}
EOF

print_status "Configuration files updated"

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
cd terraform
terraform init -upgrade
cd ..
print_status "Terraform initialized"

# Plan deployment
echo ""
echo "Planning SLZ Platform deployment..."
cd terraform
terraform plan \
  -var-file="environments/platform/terraform.tfvars" \
  -var="platform_subscription_id=$PLATFORM_SUB" \
  -var="workload_subscription_ids={workload1=\"$WORKLOAD_SUB1\",workload2=\"$WORKLOAD_SUB2\"}" \
  -out=tfplan.binary
cd ..

print_status "Plan completed successfully"

echo ""
echo "📋 Plan Summary:"
echo "  Platform Subscription: $PLATFORM_SUB"
echo "  Workload 1 Subscription: $WORKLOAD_SUB1"
echo "  Workload 2 Subscription: $WORKLOAD_SUB2"
echo ""
echo "Resources to be created:"
echo "  ✓ Resource Group (slz-we-platform-rg)"
echo "  ✓ Azure Key Vault (Premium tier with purge protection)"
echo "  ✓ Storage Account (for audit logs with GRS redundancy)"
echo "  ✓ Log Analytics Workspace (2-year retention)"
echo "  ✓ Azure Policies (encryption, data residency, TLS enforcement)"
echo ""

read -p "Do you want to apply this configuration? (yes/no): " APPLY_CONFIRM

if [ "$APPLY_CONFIRM" == "yes" ] || [ "$APPLY_CONFIRM" == "y" ]; then
    echo "Applying SLZ deployment..."
    cd terraform
    terraform apply tfplan.binary
    cd ..
    print_status "SLZ deployment completed!"
    
    echo ""
    echo "📊 Next steps:"
    echo "  1. Review resources in Azure Portal"
    echo "  2. Check Log Analytics Workspace for audit logs"
    echo "  3. Verify Key Vault access and policies"
    echo "  4. Configure CI/CD secrets in GitHub"
    echo "  5. Push changes to your repository"
else
    print_warning "Deployment cancelled"
    echo "You can apply the plan later by running:"
    echo "  cd terraform"
    echo "  terraform apply tfplan.binary"
fi
