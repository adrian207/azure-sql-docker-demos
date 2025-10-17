# Environment Management Guide

## 🎯 **TL;DR - Quick Answer to Your Question**

**Question:** "Do we need separate scenarios (branches) or just options?"

**Answer:** **JUST OPTIONS** (configuration-based) ✅

- ✅ **One branch** (`main`)
- ✅ **Multiple environment configs** (`dev.tfvars`, `staging.tfvars`, `prod.tfvars`)
- ✅ **Terraform workspaces** for state isolation

**Why not branches?** Branches for environments lead to code drift, merge conflicts, and maintenance nightmares.

---

## 📊 **Environment Comparison Table**

| Aspect | Development | Staging | Production |
|--------|------------|---------|------------|
| **Purpose** | Daily development | Pre-prod testing | Production workloads |
| **Linux VM** | D4s_v3 (4 vCPU, 16 GB) | D8s_v3 (8 vCPU, 32 GB) | E8s_v3 (8 vCPU, 64 GB) |
| **Windows VM** | D2s_v3 (2 vCPU, 8 GB) | D4s_v3 (4 vCPU, 16 GB) | D4s_v3 (4 vCPU, 16 GB) |
| **Data Disks** | 256 GB | 512 GB | 1 TB |
| **Auto-Shutdown** | 6 PM daily | 8 PM daily | Disabled |
| **Monthly Cost (8hrs)** | ~$145 | ~$309 | ~$896 (24/7) |
| **Monthly Cost (24/7)** | ~$350 | ~$696 | ~$896 |
| **SQL Edition** | Developer | Developer | Standard/Enterprise |
| **Native SQL on Windows** | No (containers only) | Yes (for testing) | Yes |
| **Security Level** | Basic | Medium | High |
| **Backup** | None | Weekly | Daily + Retention |
| **Monitoring** | Basic | Full | Full + Alerting |
| **Use Cases** | - Feature development<br>- Learning<br>- Quick testing | - Integration testing<br>- UAT<br>- Performance testing | - Production demos<br>- Critical workloads<br>- Customer-facing |

---

## 🚀 **Quick Start - Deploy Any Environment**

### Linux/Mac

```bash
# Development
cd terraform
./scripts/deploy-env.sh dev apply

# Staging
./scripts/deploy-env.sh staging apply

# Production (with extra confirmation)
./scripts/deploy-env.sh prod apply
```

### Windows (PowerShell)

```powershell
# Development
cd terraform
.\scripts\deploy-env.ps1 -Environment dev -Action apply

# Staging
.\scripts\deploy-env.ps1 -Environment staging -Action apply

# Production
.\scripts\deploy-env.ps1 -Environment prod -Action apply
```

### Manual Deployment

```bash
cd terraform

# Create workspace
terraform workspace new dev

# Deploy
terraform apply -var-file="environments/dev.tfvars"
```

---

## 🏗️ **Architecture: One Codebase, Multiple Configs**

```
azure-sql-docker-demos/
├── terraform/
│   ├── main.tf                    ← Same code for all environments
│   ├── network.tf                 ← Same code for all environments
│   ├── linux-vm.tf                ← Same code for all environments
│   ├── windows-vm.tf              ← Same code for all environments
│   ├── variables.tf               ← Variable definitions
│   └── environments/              ← ONLY THING THAT CHANGES
│       ├── dev.tfvars             ← Dev configuration
│       ├── staging.tfvars         ← Staging configuration
│       └── prod.tfvars            ← Prod configuration
```

**Key Principle:** 
- **Code is shared** (DRY principle)
- **Configs are different** (environment-specific)

---

## 🔐 **Security Improvements (Now Fixed!)**

### Before (INSECURE ❌)

```hcl
# variables.tf
variable "allowed_ip_ranges" {
  default = ["0.0.0.0/0"]  # Open to entire internet!
}

variable "guacamole_admin_password" {
  default = "ChangeMe123!"  # Default password!
}
```

### After (SECURE ✅)

```hcl
# variables.tf
variable "allowed_ip_ranges" {
  # NO DEFAULT - must be specified!
  validation {
    condition     = !contains(var.allowed_ip_ranges, "0.0.0.0/0")
    error_message = "Never use 0.0.0.0/0!"
  }
}

variable "guacamole_admin_password" {
  # NO DEFAULT - must be specified!
  validation {
    condition     = length(var.guacamole_admin_password) >= 12
    error_message = "Password must be 12+ characters."
  }
}
```

**Result:** Terraform will **fail** if you forget to set passwords or try to use 0.0.0.0/0!

---

## 📝 **How to Use Environments**

### 1. Choose Your Environment

```bash
# For daily development work
ENVIRONMENT=dev

# For pre-production testing
ENVIRONMENT=staging

# For production deployment
ENVIRONMENT=prod
```

### 2. Edit Configuration

```bash
# Copy template if creating new environment
cp terraform/environments/dev.tfvars terraform/environments/myenv.tfvars

# Edit the file
code terraform/environments/$ENVIRONMENT.tfvars

# Key things to set:
# 1. allowed_ip_ranges = ["YOUR_IP/32"]
# 2. admin_password = "YourStrongPassword123!"
# 3. sql_sa_password = "YourSQLPassword123!"
# 4. guacamole_admin_password = "YourGuacPassword123!"
```

### 3. Deploy

```bash
# Preview changes (safe)
./scripts/deploy-env.sh $ENVIRONMENT plan

# Apply changes
./scripts/deploy-env.sh $ENVIRONMENT apply

# Destroy (with confirmation)
./scripts/deploy-env.sh $ENVIRONMENT destroy
```

---

## 🔄 **Workflow: Dev → Staging → Prod**

### Typical Development Cycle

```
1. DEVELOP in dev
   ↓
   - Make infrastructure changes
   - Test in dev environment
   - Commit code changes to main branch
   
2. VALIDATE in staging
   ↓
   - Deploy same code to staging
   - Run integration tests
   - Perform UAT
   - Load testing
   
3. DEPLOY to prod
   ↓
   - Deploy tested code to production
   - Monitor closely
   - Rollback plan ready
```

### Example Workflow

```bash
# 1. Make changes and test in dev
git checkout main
# Edit terraform files
./scripts/deploy-env.sh dev apply
# Test...

# 2. Commit changes
git add .
git commit -m "feat: add accelerated networking"
git push origin main

# 3. Deploy to staging for validation
./scripts/deploy-env.sh staging apply
# Run tests...

# 4. Deploy to production
./scripts/deploy-env.sh prod plan  # Review carefully!
./scripts/deploy-env.sh prod apply
```

---

## 🛠️ **Terraform Workspaces Explained**

### What Are Workspaces?

Workspaces provide **state file isolation** so you can deploy the same code to multiple environments without conflicts.

### Workspace Commands

```bash
# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new myenv

# Switch workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace (after destroying resources)
terraform workspace delete myenv
```

### How Workspaces Work

```
.terraform/
└── terraform.tfstate.d/
    ├── dev/
    │   └── terraform.tfstate      ← Dev state
    ├── staging/
    │   └── terraform.tfstate      ← Staging state
    └── prod/
        └── terraform.tfstate      ← Prod state
```

Each workspace has **completely isolated state**.

---

## 💰 **Cost Comparison**

### Monthly Costs by Environment

| Scenario | Dev | Staging | Prod |
|----------|-----|---------|------|
| **24/7 operation** | $350 | $696 | $896 |
| **12 hrs/day** | $175 | $348 | $896 |
| **8 hrs/day** | $145 | $309 | $896 |

### Cost Optimization Tips

**Development:**
- ✅ Auto-shutdown at 6 PM
- ✅ Smaller VMs (D4s_v3, D2s_v3)
- ✅ Smaller disks (256 GB)
- ✅ Containers only (no native SQL)
- **Savings:** 58% vs 24/7

**Staging:**
- ✅ Auto-shutdown at 8 PM
- ✅ Production-like VMs
- ✅ Test all features
- **Savings:** 56% vs 24/7

**Production:**
- ❌ No auto-shutdown
- ✅ Memory-optimized VMs
- ✅ Larger disks
- ✅ 24/7 availability

---

## 🔍 **Troubleshooting**

### Issue: "Wrong workspace selected"

```bash
# Check current workspace
terraform workspace show

# Switch to correct workspace
terraform workspace select dev
```

### Issue: "Variable not defined"

```bash
# Make sure you're using the right var file
terraform apply -var-file="environments/dev.tfvars"

# Check if all required variables are set
grep 'admin_password.*= ""' environments/dev.tfvars
```

### Issue: "0.0.0.0/0 not allowed" error

```bash
# Good! Security validation working!
# Get your IP
curl ifconfig.me

# Update tfvars
allowed_ip_ranges = ["YOUR_IP/32"]
```

### Issue: "State locked"

```bash
# Someone else is running Terraform
# Wait for them to finish, or force unlock (dangerous!)
terraform force-unlock <lock-id>
```

---

## ✅ **Best Practices**

### DO ✅

- ✅ Use workspaces for state isolation
- ✅ Keep environment configs in separate files
- ✅ Use strong, unique passwords per environment
- ✅ Restrict IP access to specific addresses
- ✅ Test in dev before staging
- ✅ Test in staging before prod
- ✅ Use remote state backend (Azure Storage)
- ✅ Enable state locking
- ✅ Tag all resources with environment
- ✅ Use auto-shutdown in non-prod

### DON'T ❌

- ❌ Use branches for environments
- ❌ Use same passwords across environments
- ❌ Skip validation in dev
- ❌ Deploy directly to prod without staging
- ❌ Use 0.0.0.0/0 for IP ranges
- ❌ Store passwords in git (use .tfvars, not committed)
- ❌ Share state files between environments
- ❌ Forget to switch workspaces
- ❌ Run prod auto-shutdown
- ❌ Use Developer SQL edition in production

---

## 📚 **Additional Resources**

- [Terraform Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)
- [Environment Strategy](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)
- [Azure Best Practices](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Terraform Security](https://www.terraform.io/docs/language/values/variables.html#sensitive)

---

## 🎓 **Summary**

### Your Question: "Branches or Options?"

**Answer: OPTIONS** ✅

We implemented:
1. ✅ **One codebase** (main branch)
2. ✅ **Three environments** (dev, staging, prod)
3. ✅ **Configuration files** for each environment
4. ✅ **Terraform workspaces** for state isolation
5. ✅ **Deployment scripts** with safety checks
6. ✅ **Security validations** (no more dangerous defaults!)
7. ✅ **Cost optimization** per environment

### What You Get

- **Same code** across all environments (no drift!)
- **Different configs** per environment (flexibility!)
- **Isolated state** (safety!)
- **Easy promotion** (dev → staging → prod)
- **Cost-optimized** (right-size each environment)
- **Secure by default** (validation prevents mistakes)

### Next Steps

1. Edit `terraform/environments/dev.tfvars` with your passwords and IP
2. Run `./scripts/deploy-env.sh dev apply`
3. Test in dev
4. Promote to staging
5. Deploy to prod (when ready)

**🎉 You now have a production-ready, multi-environment infrastructure!**

