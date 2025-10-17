#!/bin/bash
# Deploy to specific environment with safety checks

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

# Check if environment is provided
if [ -z "$1" ]; then
    print_error "No environment specified"
    echo ""
    echo "Usage: $0 [dev|staging|prod] [plan|apply|destroy]"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan          # Preview dev changes"
    echo "  $0 dev apply         # Deploy to dev"
    echo "  $0 staging apply     # Deploy to staging"
    echo "  $0 prod plan         # Preview prod changes (safe)"
    exit 1
fi

ENV=$1
ACTION=${2:-"plan"}  # Default to plan for safety

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENV"
    echo "Valid environments: dev, staging, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION"
    echo "Valid actions: plan, apply, destroy"
    exit 1
fi

# Change to terraform directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
cd "$TERRAFORM_DIR"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
fi

# Check if Azure CLI is installed and authenticated
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Azure authentication
if ! az account show &> /dev/null; then
    print_error "Not authenticated to Azure"
    echo "Run: az login"
    exit 1
fi

# Check if environment config exists
ENV_FILE="environments/${ENV}.tfvars"
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file not found: $ENV_FILE"
    exit 1
fi

# Check if passwords are set (not empty)
if grep -q 'admin_password.*= ""' "$ENV_FILE" || \
   grep -q 'sql_sa_password.*= ""' "$ENV_FILE" || \
   grep -q 'guacamole_admin_password.*= ""' "$ENV_FILE"; then
    print_error "Passwords not set in $ENV_FILE"
    echo ""
    echo "Please edit $ENV_FILE and set:"
    echo "  - admin_password"
    echo "  - sql_sa_password"
    echo "  - guacamole_admin_password"
    exit 1
fi

# Check if IP address is configured
if grep -q 'YOUR_IP_HERE' "$ENV_FILE"; then
    print_error "IP address not configured in $ENV_FILE"
    echo ""
    echo "Your current IP: $(curl -s ifconfig.me)"
    echo "Update allowed_ip_ranges in $ENV_FILE"
    exit 1
fi

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    terraform init
fi

# Create or select workspace
print_info "Switching to $ENV workspace..."
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"

# Verify current workspace
CURRENT_WORKSPACE=$(terraform workspace show)
if [ "$CURRENT_WORKSPACE" != "$ENV" ]; then
    print_error "Failed to switch to $ENV workspace"
    exit 1
fi

print_success "Using workspace: $CURRENT_WORKSPACE"

# Show current Azure subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
print_info "Azure Subscription: $SUBSCRIPTION"

echo ""
echo "======================================"
echo "  Environment: $ENV"
echo "  Action: $ACTION"
echo "  Workspace: $CURRENT_WORKSPACE"
echo "  Config: $ENV_FILE"
echo "======================================"
echo ""

# Extra confirmation for production
if [ "$ENV" == "prod" ]; then
    print_warning "You are about to $ACTION PRODUCTION environment!"
    echo ""
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Deployment cancelled"
        exit 1
    fi
fi

# Extra confirmation for destroy
if [ "$ACTION" == "destroy" ]; then
    print_warning "This will DESTROY all resources in $ENV!"
    echo ""
    read -p "Type 'destroy-$ENV' to confirm: " confirm
    if [ "$confirm" != "destroy-$ENV" ]; then
        print_error "Destroy cancelled"
        exit 1
    fi
fi

# Execute terraform command
case $ACTION in
    plan)
        print_info "Running terraform plan..."
        terraform plan -var-file="$ENV_FILE" -out="${ENV}.tfplan"
        print_success "Plan saved to ${ENV}.tfplan"
        ;;
    apply)
        # If plan exists, use it
        if [ -f "${ENV}.tfplan" ]; then
            print_info "Applying saved plan..."
            terraform apply "${ENV}.tfplan"
            rm "${ENV}.tfplan"
        else
            print_info "Running terraform apply..."
            terraform apply -var-file="$ENV_FILE"
        fi
        
        print_success "Deployment complete!"
        echo ""
        print_info "Connection information:"
        terraform output connection_instructions
        ;;
    destroy)
        print_info "Running terraform destroy..."
        terraform destroy -var-file="$ENV_FILE"
        print_success "Environment destroyed"
        ;;
esac

print_success "Done!"

