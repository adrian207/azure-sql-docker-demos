# Quick Start Guide - 5 Minutes to Deployment

This guide will get your SQL Server Docker demo environment running in 5 minutes.

## Prerequisites

- ✅ Azure subscription
- ✅ Azure CLI installed and authenticated
- ✅ Terraform ≥ 1.5.0 installed
- ✅ SSH key pair generated
- ✅ 5-10 minutes of time

## Step 1: Clone and Configure (2 minutes)

```bash
# Clone repository
git clone https://github.com/adrian207/azure-sql-docker-demos.git
cd azure-sql-docker-demos/terraform

# Authenticate to Azure
az login
az account set --subscription "Your-Subscription-Name"

# Get your public IP for security
MY_IP=$(curl -s ifconfig.me)
echo "Your public IP: $MY_IP"

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# Admin Configuration
admin_username = "sqladmin"
admin_password = "ChangeMe123!SecurePassword"     # ⚠️ Change this!
sql_sa_password = "ChangeMe123!SQLPassword"       # ⚠️ Change this!

# Security - IMPORTANT: Restrict to your IP!
allowed_ip_ranges = ["$MY_IP/32"]

# Cost Optimization
auto_shutdown_enabled = true
auto_shutdown_time = "1900"  # 7 PM shutdown

# Optional: Use smaller VMs for testing
# linux_vm_size = "Standard_D4s_v3"    # 4 vCPU instead of 8
# windows_vm_size = "Standard_D2s_v3"  # 2 vCPU instead of 4
EOF

# Verify SSH key exists
ls ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## Step 2: Deploy Infrastructure (10-15 minutes)

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy everything
terraform apply -auto-approve

# ☕ Get coffee - deployment takes ~10-15 minutes
```

## Step 3: Access Your Environment (1 minute)

After deployment completes, Terraform will output connection information:

```bash
# View all connection details
terraform output

# Quick access to specific values
LINUX_IP=$(terraform output -raw linux_public_ip)
GUAC_URL=$(terraform output -raw guacamole_url)
GRAFANA_URL=$(terraform output -raw grafana_url)

echo "
🌐 ACCESS YOUR ENVIRONMENT:
===========================
Guacamole:  $GUAC_URL
Grafana:    $GRAFANA_URL
SSH:        ssh sqladmin@$LINUX_IP

📋 DEFAULT CREDENTIALS:
=======================
Guacamole:  guacadmin / guacadmin
Grafana:    admin / admin
SQL Server: sa / <your sql_sa_password>
"
```

## Step 4: Verify Everything Works (2 minutes)

### Check SQL Server Containers

```bash
# SSH into Linux VM
ssh sqladmin@$LINUX_IP

# View running containers
docker ps

# Expected output:
# - sql-primary (port 1433)
# - sql-secondary (port 1434)
# - sql-witness (port 1435)
# - guacamole (port 8080)
# - grafana (port 3000)
# - prometheus (port 9090)

# Test SQL connection
docker exec -it sql-primary /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'ChangeMe123!SQLPassword' \
  -Q "SELECT @@VERSION"

# Expected: SQL Server 2022 version information
```

### Access Web Interfaces

1. **Guacamole** (Browser-based RDP/SSH)
   - Open: `http://<linux-ip>:8080/guacamole`
   - Login: `guacadmin` / `guacadmin`
   - Click "Windows Server 2022" to access Windows VM

2. **Grafana** (Monitoring Dashboards)
   - Open: `http://<linux-ip>:3000`
   - Login: `admin` / `admin`
   - Change password on first login

3. **Prometheus** (Metrics)
   - Open: `http://<linux-ip>:9090`
   - No authentication required (demo only!)

### Connect to SQL Server from Windows (via SSMS)

1. Access Windows VM via Guacamole
2. Open SQL Server Management Studio (desktop shortcut)
3. Connect to containers:
   ```
   Server: <linux-private-ip>,1433    # Primary
   Server: <linux-private-ip>,1434    # Secondary
   Server: <linux-private-ip>,1435    # Witness
   
   Authentication: SQL Server Authentication
   Login: sa
   Password: <your-sql-sa-password>
   ```

## Quick Reference

### Connection Information

```bash
# Get private IPs from Terraform
terraform output -json deployment_summary | jq
```

| Component | Access | Credentials |
|-----------|--------|-------------|
| **Guacamole** | http://\<linux-public-ip\>:8080/guacamole | guacadmin / guacadmin |
| **Grafana** | http://\<linux-public-ip\>:3000 | admin / admin |
| **Prometheus** | http://\<linux-public-ip\>:9090 | None |
| **Linux SSH** | ssh sqladmin@\<linux-public-ip\> | SSH key |
| **Windows RDP** | Via Guacamole only | sqladmin / \<admin-password\> |
| **SQL Primary** | \<linux-private-ip\>,1433 | sa / \<sql-sa-password\> |
| **SQL Secondary** | \<linux-private-ip\>,1434 | sa / \<sql-sa-password\> |
| **SQL Witness** | \<linux-private-ip\>,1435 | sa / \<sql-sa-password\> |

### Cost Optimization

```bash
# Stop VMs when not in use (stops compute billing)
az vm deallocate --ids $(terraform output -raw linux_vm_id)
az vm deallocate --ids $(terraform output -raw windows_vm_id)

# Start VMs when needed
az vm start --ids $(terraform output -raw linux_vm_id)
az vm start --ids $(terraform output -raw windows_vm_id)

# Auto-shutdown runs nightly at configured time (default 7 PM)
```

**Monthly Costs:**
- **24/7 usage**: ~$696/month
- **8 hours/day** (with auto-shutdown): ~$309/month
- **Optimized VMs** (D4s_v3 + D2s_v3): ~$291/month

### Common Commands

```bash
# View all resources
terraform show

# Update configuration
terraform apply

# Destroy everything
terraform destroy

# SSH to Linux VM
terraform output -raw linux_public_ip | xargs -I {} ssh sqladmin@{}

# View SQL container logs
ssh sqladmin@$(terraform output -raw linux_public_ip) 'docker logs sql-primary'
```

## Next Steps

Now that your environment is running:

1. **Explore the demos:**
   - See `/docker/README.md` for SQL Server demo scenarios
   - Checkout feature branches for specific HA configurations

2. **Set up monitoring:**
   - Configure Grafana dashboards
   - Set up alerts in Prometheus

3. **Learn SQL Server HA:**
   - `feat/sql-log-shipping` - Log shipping demo
   - `feat/sql-transactional-replication` - Replication demo
   - `feat/sql-always-on-ag` - Always On AG demo

4. **Customize your environment:**
   - Modify VM sizes in `terraform.tfvars`
   - Adjust auto-shutdown times
   - Add additional SQL containers

## Troubleshooting

### Issue: Cannot connect to Guacamole

```bash
# Check if containers are running
ssh sqladmin@<linux-ip> 'docker ps'

# View Guacamole logs
ssh sqladmin@<linux-ip> 'docker logs guacamole'

# Verify NSG rules
terraform output -json | jq '.deployment_summary.value'
```

### Issue: SQL Server containers not starting

```bash
# Check container logs
ssh sqladmin@<linux-ip> 'docker logs sql-primary'

# Common causes:
# 1. Invalid SA password (must meet complexity requirements)
# 2. Insufficient memory (check VM size)
# 3. Port conflicts (check docker ps)

# Restart containers
ssh sqladmin@<linux-ip> 'cd /opt/sql-docker && docker-compose restart'
```

### Issue: High Azure costs

```bash
# Verify auto-shutdown is enabled
terraform output auto_shutdown_enabled

# Check VM sizes
terraform show | grep vm_size

# Consider smaller VMs
# Edit terraform.tfvars and apply changes
```

## Clean Up

When done with demos:

```bash
# Destroy all resources
cd terraform
terraform destroy -auto-approve

# Verify deletion in Azure Portal
az group list --query "[?contains(name, 'sql-docker-demo')]"
```

## Support

- **Documentation**: See [README.md](./README.md)
- **Issues**: https://github.com/adrian207/azure-sql-docker-demos/issues
- **Discussions**: https://github.com/adrian207/azure-sql-docker-demos/discussions
- **Email**: [adrian207@gmail.com](mailto:adrian207@gmail.com)

---

## 👤 Author

**Adrian Johnson**
- Email: [adrian207@gmail.com](mailto:adrian207@gmail.com)
- GitHub: [@adrian207](https://github.com/adrian207)

---

## Summary

✅ **What You Just Deployed:**
- 1x Rocky Linux VM (8 vCPU, 32 GB RAM) with 3 SQL Server containers
- 1x Windows Server 2022 VM (4 vCPU, 16 GB RAM) with SSMS
- Apache Guacamole for browser-based access (no VPN needed!)
- Prometheus + Grafana monitoring stack
- Auto-shutdown for cost savings
- **Total setup time: ~15 minutes**
- **Monthly cost: ~$300 (with auto-shutdown)**

🎉 **You're ready to demonstrate SQL Server high availability scenarios!**

