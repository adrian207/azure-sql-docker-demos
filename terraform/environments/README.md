# Environment Configurations

This directory contains environment-specific configurations for deploying the SQL Docker demos infrastructure.

## 🎯 **Philosophy: One Branch, Multiple Environments**

We use **configuration-based environments** (not branch-based):

```
✅ GOOD: Single main branch + environment configs
❌ BAD:  Separate branches per environment
```

## 📁 **Available Environments**

| Environment | Purpose | Cost/Month | Auto-Shutdown |
|-------------|---------|------------|---------------|
| **dev.tfvars** | Daily development | ~$145 | 6 PM |
| **staging.tfvars** | Pre-prod testing | ~$309 | 8 PM |
| **prod.tfvars** | Production | ~$896 | Disabled |

## 🚀 **Quick Start**

### Deploy Development Environment

```bash
cd terraform

# Option 1: Direct variable file
terraform apply -var-file="environments/dev.tfvars"

# Option 2: Using workspaces (recommended)
terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars"
```

### Deploy Staging Environment

```bash
cd terraform

terraform workspace new staging
terraform apply -var-file="environments/staging.tfvars"
```

### Deploy Production Environment

```bash
cd terraform

terraform workspace new prod
terraform apply -var-file="environments/prod.tfvars"
```

## 📊 **Environment Comparison**

### Development
**Purpose:** Daily development and testing
- **VM Sizes:** D4s_v3 (Linux), D2s_v3 (Windows)
- **Disks:** 256 GB
- **Cost:** ~$145/month (8hrs/day)
- **Features:** Minimal, containers only
- **Shutdown:** 6 PM daily
- **Use Case:** Learning, feature development

### Staging
**Purpose:** Pre-production validation
- **VM Sizes:** D8s_v3 (Linux), D4s_v3 (Windows)
- **Disks:** 512 GB
- **Cost:** ~$309/month (12hrs/day)
- **Features:** All features enabled
- **Shutdown:** 8 PM daily
- **Use Case:** Integration testing, UAT

### Production
**Purpose:** Production workloads (if applicable)
- **VM Sizes:** E8s_v3 (Linux), D4s_v3 (Windows)
- **Disks:** 1 TB
- **Cost:** ~$896/month (24/7)
- **Features:** Full stack + security
- **Shutdown:** Disabled
- **Use Case:** Production demos, critical workloads

## 🔧 **Customizing for Your Environment**

### Step 1: Copy Template

```bash
cp environments/dev.tfvars environments/myenv.tfvars
```

### Step 2: Edit Configuration

```bash
# Edit the file
code environments/myenv.tfvars

# Key things to change:
# 1. allowed_ip_ranges - YOUR IP!
# 2. Passwords (all required)
# 3. VM sizes (if needed)
# 4. Tags (owner, cost center)
```

### Step 3: Deploy

```bash
terraform workspace new myenv
terraform apply -var-file="environments/myenv.tfvars"
```

## 🏢 **Terraform Workspaces**

### Why Use Workspaces?

Workspaces provide **state isolation** between environments:

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new staging

# Switch workspace
terraform workspace select dev

# Current workspace
terraform workspace show

# Delete workspace (after destroying resources!)
terraform workspace delete staging
```

### Workspace Benefits

✅ **Isolated state** - Each environment has separate state  
✅ **Same code** - No code duplication  
✅ **Easy switching** - Change environments quickly  
✅ **Safe operations** - Can't accidentally destroy wrong environment  

### Workspace Structure

```
.terraform/
├── terraform.tfstate.d/
│   ├── dev/
│   │   └── terraform.tfstate
│   ├── staging/
│   │   └── terraform.tfstate
│   └── prod/
│       └── terraform.tfstate
└── environment (current workspace)
```

## 🔐 **Security Best Practices**

### For Development
```bash
# Generate random passwords
openssl rand -base64 24

# Restrict to your IP only
allowed_ip_ranges = ["$(curl -s ifconfig.me)/32"]
```

### For Staging
```bash
# Use office/VPN ranges
allowed_ip_ranges = [
  "OFFICE_IP/32",
  "VPN_RANGE/24"
]
```

### For Production
```bash
# ⚠️ CRITICAL: Use Azure Key Vault!
# Do NOT store passwords in tfvars in production

# Reference Key Vault in variables:
data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-sa-password"
  key_vault_id = var.key_vault_id
}
```

## 📝 **Environment Promotion Workflow**

### Recommended Flow

```
dev → staging → prod
```

### Promotion Steps

1. **Develop in dev**
   ```bash
   terraform workspace select dev
   terraform apply -var-file="environments/dev.tfvars"
   # Test changes
   ```

2. **Validate in staging**
   ```bash
   terraform workspace select staging
   terraform apply -var-file="environments/staging.tfvars"
   # Run integration tests
   # Perform UAT
   ```

3. **Deploy to prod**
   ```bash
   terraform workspace select prod
   terraform plan -var-file="environments/prod.tfvars"
   # Review plan carefully!
   terraform apply -var-file="environments/prod.tfvars"
   ```

## 🛠️ **Helper Scripts**

### Deploy Script

```bash
#!/bin/bash
# deploy.sh
ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh [dev|staging|prod]"
  exit 1
fi

echo "Deploying to $ENV environment..."
terraform workspace select $ENV || terraform workspace new $ENV
terraform apply -var-file="environments/${ENV}.tfvars"
```

### Destroy Script

```bash
#!/bin/bash
# destroy.sh
ENV=$1

echo "⚠️  WARNING: This will destroy the $ENV environment!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" == "yes" ]; then
  terraform workspace select $ENV
  terraform destroy -var-file="environments/${ENV}.tfvars"
fi
```

## 🔍 **Troubleshooting**

### Issue: Wrong workspace

```bash
# Check current workspace
terraform workspace show

# Switch to correct workspace
terraform workspace select dev
```

### Issue: State locked

```bash
# Check lock status
terraform force-unlock <lock-id>

# Be careful - only use if you're sure no one else is running terraform
```

### Issue: Different configs between environments

```bash
# Show diff between environments
diff environments/dev.tfvars environments/staging.tfvars
```

## 📚 **Additional Resources**

- [Terraform Workspaces Documentation](https://www.terraform.io/docs/language/state/workspaces.html)
- [Environment Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

## ❓ **FAQ**

**Q: Should I use branches or workspaces?**  
A: **Workspaces**. Branches for environments is an anti-pattern that leads to code drift.

**Q: Can I have multiple workspaces with the same config?**  
A: Yes! You could have `dev-alice` and `dev-bob` using the same `dev.tfvars`.

**Q: What happens if I forget to switch workspaces?**  
A: Terraform operations affect the current workspace only. Use `terraform workspace show` to verify.

**Q: How do I backup my state files?**  
A: Use remote state backend (Azure Storage) with versioning enabled.

**Q: Can I use the same database between environments?**  
A: **No**. Each environment should be completely isolated.

---

**Need help?** Open an issue or check the main [README.md](../../README.md)

