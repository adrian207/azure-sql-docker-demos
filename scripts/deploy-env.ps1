# PowerShell version of deploy script for Windows users
# Deploy to specific environment with safety checks

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','staging','prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('plan','apply','destroy')]
    [string]$Action = 'plan'
)

$ErrorActionPreference = "Stop"

# Helper functions
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($Message) {
    Write-ColorOutput Green "✅ $Message"
}

function Write-Error-Custom($Message) {
    Write-ColorOutput Red "❌ ERROR: $Message"
}

function Write-Warning-Custom($Message) {
    Write-ColorOutput Yellow "⚠️  WARNING: $Message"
}

function Write-Info($Message) {
    Write-ColorOutput Cyan "ℹ️  $Message"
}

# Change to terraform directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $ScriptDir "..\terraform"
Set-Location $TerraformDir

# Check if terraform is installed
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Terraform is not installed"
    Write-Output "Install from: https://www.terraform.io/downloads"
    exit 1
}

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Azure CLI is not installed"
    Write-Output "Install from: https://aka.ms/installazurecliwindows"
    exit 1
}

# Check Azure authentication
try {
    az account show | Out-Null
} catch {
    Write-Error-Custom "Not authenticated to Azure"
    Write-Output "Run: az login"
    exit 1
}

# Check if environment config exists
$EnvFile = "environments\$Environment.tfvars"
if (!(Test-Path $EnvFile)) {
    Write-Error-Custom "Environment file not found: $EnvFile"
    exit 1
}

# Check if passwords are set
$fileContent = Get-Content $EnvFile -Raw
if ($fileContent -match 'admin_password\s*=\s*""' -or
    $fileContent -match 'sql_sa_password\s*=\s*""' -or
    $fileContent -match 'guacamole_admin_password\s*=\s*""') {
    Write-Error-Custom "Passwords not set in $EnvFile"
    Write-Output ""
    Write-Output "Please edit $EnvFile and set:"
    Write-Output "  - admin_password"
    Write-Output "  - sql_sa_password"
    Write-Output "  - guacamole_admin_password"
    exit 1
}

# Check if IP is configured
if ($fileContent -match 'YOUR_IP_HERE') {
    Write-Error-Custom "IP address not configured in $EnvFile"
    Write-Output ""
    Write-Output "Your current IP: $(Invoke-RestMethod -Uri 'https://ifconfig.me/ip')"
    Write-Output "Update allowed_ip_ranges in $EnvFile"
    exit 1
}

# Initialize terraform if needed
if (!(Test-Path ".terraform")) {
    Write-Info "Initializing Terraform..."
    terraform init
}

# Create or select workspace
Write-Info "Switching to $Environment workspace..."
terraform workspace select $Environment 2>$null
if ($LASTEXITCODE -ne 0) {
    terraform workspace new $Environment
}

# Verify workspace
$currentWorkspace = terraform workspace show
if ($currentWorkspace -ne $Environment) {
    Write-Error-Custom "Failed to switch to $Environment workspace"
    exit 1
}

Write-Success "Using workspace: $currentWorkspace"

# Show Azure subscription
$subscription = az account show --query name -o tsv
Write-Info "Azure Subscription: $subscription"

Write-Output ""
Write-Output "======================================"
Write-Output "  Environment: $Environment"
Write-Output "  Action: $Action"
Write-Output "  Workspace: $currentWorkspace"
Write-Output "  Config: $EnvFile"
Write-Output "======================================"
Write-Output ""

# Extra confirmation for production
if ($Environment -eq 'prod') {
    Write-Warning-Custom "You are about to $Action PRODUCTION environment!"
    Write-Output ""
    $confirm = Read-Host "Type 'yes' to confirm"
    if ($confirm -ne 'yes') {
        Write-Error-Custom "Deployment cancelled"
        exit 1
    }
}

# Extra confirmation for destroy
if ($Action -eq 'destroy') {
    Write-Warning-Custom "This will DESTROY all resources in $Environment!"
    Write-Output ""
    $confirm = Read-Host "Type 'destroy-$Environment' to confirm"
    if ($confirm -ne "destroy-$Environment") {
        Write-Error-Custom "Destroy cancelled"
        exit 1
    }
}

# Execute terraform command
switch ($Action) {
    'plan' {
        Write-Info "Running terraform plan..."
        terraform plan -var-file="$EnvFile" -out="$Environment.tfplan"
        Write-Success "Plan saved to $Environment.tfplan"
    }
    'apply' {
        if (Test-Path "$Environment.tfplan") {
            Write-Info "Applying saved plan..."
            terraform apply "$Environment.tfplan"
            Remove-Item "$Environment.tfplan"
        } else {
            Write-Info "Running terraform apply..."
            terraform apply -var-file="$EnvFile"
        }
        
        Write-Success "Deployment complete!"
        Write-Output ""
        Write-Info "Connection information:"
        terraform output connection_instructions
    }
    'destroy' {
        Write-Info "Running terraform destroy..."
        terraform destroy -var-file="$EnvFile"
        Write-Success "Environment destroyed"
    }
}

Write-Success "Done!"

