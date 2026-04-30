# SLZ Quick Deployment Script (PowerShell)
# This script helps you quickly deploy your Sovereign Landing Zone on Windows

param(
    [string]$PlatformSubscriptionId,
    [string]$Workload1SubscriptionId,
    [string]$Workload2SubscriptionId
)

Write-Host "🚀 Sovereign Landing Zone (SLZ) Deployment Script (PowerShell)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

function Test-Prerequisite {
    param(
        [string]$Command,
        [string]$Name
    )
    
    try {
        $null = & $Command --version 2>&1
        Write-Host "✓ $Name installed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ $Name not found. Please install $Name." -ForegroundColor Red
        return $false
    }
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$hasAllPrerequisites = $true
$hasAllPrerequisites = (Test-Prerequisite -Command "terraform" -Name "Terraform") -and $hasAllPrerequisites
$hasAllPrerequisites = (Test-Prerequisite -Command "az" -Name "Azure CLI") -and $hasAllPrerequisites
$hasAllPrerequisites = (Test-Prerequisite -Command "git" -Name "Git") -and $hasAllPrerequisites

if (-not $hasAllPrerequisites) {
    Write-Host ""
    Write-Host "Please install missing prerequisites and try again." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Prerequisites check completed!" -ForegroundColor Green
Write-Host ""

# Get subscription IDs if not provided
if (-not $PlatformSubscriptionId) {
    $PlatformSubscriptionId = Read-Host "Platform Subscription ID"
}

if (-not $Workload1SubscriptionId) {
    $Workload1SubscriptionId = Read-Host "Workload 1 Subscription ID"
}

if (-not $Workload2SubscriptionId) {
    $Workload2SubscriptionId = Read-Host "Workload 2 Subscription ID"
}

# Validate subscription ID format
$guidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
if ($PlatformSubscriptionId -notmatch $guidPattern) {
    Write-Host "✗ Invalid Platform subscription ID format" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Updating Terraform configuration files..." -ForegroundColor Yellow

# Create platform terraform.tfvars
$platformTfvars = @"
environment            = "platform"
region                 = "westeurope"
location_code          = "we"
organization_name      = "slz"

platform_subscription_id = "$PlatformSubscriptionId"

workload_subscription_ids = {
  workload1 = "$Workload1SubscriptionId"
  workload2 = "$Workload2SubscriptionId"
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
"@

$platformTfvars | Out-File -FilePath "terraform/environments/platform/terraform.tfvars" -Encoding UTF8

# Create workload terraform.tfvars
$workloadTfvars = @"
environment            = "workload"
region                 = "westeurope"
location_code          = "we"
organization_name      = "slz"

platform_subscription_id = "$PlatformSubscriptionId"

workload_subscription_ids = {
  workload1 = "$Workload1SubscriptionId"
  workload2 = "$Workload2SubscriptionId"
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
"@

$workloadTfvars | Out-File -FilePath "terraform/environments/workload/terraform.tfvars" -Encoding UTF8

Write-Host "✓ Configuration files updated" -ForegroundColor Green

# Initialize Terraform
Write-Host ""
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
Push-Location terraform
terraform init -upgrade
Pop-Location
Write-Host "✓ Terraform initialized" -ForegroundColor Green

# Plan deployment
Write-Host ""
Write-Host "Planning SLZ Platform deployment..." -ForegroundColor Yellow
Push-Location terraform
terraform plan `
  -var-file="environments/platform/terraform.tfvars" `
  -var="platform_subscription_id=$PlatformSubscriptionId" `
  -var="workload_subscription_ids={workload1=`"$Workload1SubscriptionId`",workload2=`"$Workload2SubscriptionId`"}" `
  -out=tfplan.binary
Pop-Location

Write-Host "✓ Plan completed successfully" -ForegroundColor Green

# Display summary
Write-Host ""
Write-Host "📋 Plan Summary:" -ForegroundColor Cyan
Write-Host "  Platform Subscription: $PlatformSubscriptionId"
Write-Host "  Workload 1 Subscription: $Workload1SubscriptionId"
Write-Host "  Workload 2 Subscription: $Workload2SubscriptionId"
Write-Host ""
Write-Host "Resources to be created:" -ForegroundColor Cyan
Write-Host "  ✓ Resource Group (slz-we-platform-rg)"
Write-Host "  ✓ Azure Key Vault (Premium tier with purge protection)"
Write-Host "  ✓ Storage Account (for audit logs with GRS redundancy)"
Write-Host "  ✓ Log Analytics Workspace (2-year retention)"
Write-Host "  ✓ Azure Policies (encryption, data residency, TLS enforcement)"
Write-Host ""

$applyConfirm = Read-Host "Do you want to apply this configuration? (yes/no)"

if ($applyConfirm -eq "yes" -or $applyConfirm -eq "y") {
    Write-Host "Applying SLZ deployment..." -ForegroundColor Yellow
    Push-Location terraform
    terraform apply tfplan.binary
    Pop-Location
    Write-Host "✓ SLZ deployment completed!" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📊 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review resources in Azure Portal"
    Write-Host "  2. Check Log Analytics Workspace for audit logs"
    Write-Host "  3. Verify Key Vault access and policies"
    Write-Host "  4. Configure CI/CD secrets in GitHub"
    Write-Host "  5. Push changes to your repository"
}
else {
    Write-Host "⚠ Deployment cancelled" -ForegroundColor Yellow
    Write-Host "You can apply the plan later by running:" -ForegroundColor Yellow
    Write-Host "  cd terraform"
    Write-Host "  terraform apply tfplan.binary"
}
