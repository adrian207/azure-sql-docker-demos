# Azure SQL Server Docker Demos

<div align="center">

**Production-Grade SQL Server Container Demonstrations on Azure**

[![Terraform](https://img.shields.io/badge/Terraform-≥1.5-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![Docker](https://img.shields.io/badge/Docker-Container-2496ED?logo=docker)](https://www.docker.com/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)

**Demonstrate SQL Server high availability scenarios using Docker containers on Azure**

[Documentation](#documentation) • [Quick Start](#quick-start) • [Architecture](#architecture) • [Demos](#sql-server-demos) • [Cost Analysis](#cost-analysis)

</div>

---

## 🎯 Overview

This project demonstrates **SQL Server high availability and disaster recovery scenarios** using containerized SQL Server instances on Azure infrastructure. It provides a cost-effective platform for learning, testing, and demonstrating enterprise SQL Server features including:

- 🔄 **Log Shipping** - Automated backup/restore for warm standby
- 🔗 **Transactional Replication** - Real-time data distribution
- ⚡ **Always On Availability Groups** - Enterprise HA with automatic failover
- 📊 **Monitoring & Observability** - Prometheus + Grafana dashboards
- 🖥️ **Remote Access** - Apache Guacamole for browser-based management

---

## 🏗️ Architecture

### Infrastructure Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Resource Group                         │
│                     West US 2 Region                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │           Virtual Network (10.0.0.0/16)                    │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  Linux Subnet (10.0.1.0/24)                               │ │
│  │  ┌───────────────────────────────────────┐                │ │
│  │  │  Rocky Linux 9 VM (Standard_D8s_v3)   │                │ │
│  │  │  8 vCPU | 32 GB RAM | 1 TB SSD        │                │ │
│  │  ├───────────────────────────────────────┤                │ │
│  │  │  🐳 Docker Containers:                │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ SQL Server 2022 (Primary)       │  │                │ │
│  │  │  │ Port: 1433                      │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ SQL Server 2022 (Secondary)     │  │                │ │
│  │  │  │ Port: 1434                      │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ SQL Server 2022 (Witness)       │  │                │ │
│  │  │  │ Port: 1435 (AG scenarios)       │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ Prometheus (Monitoring)         │  │                │ │
│  │  │  │ Port: 9090                      │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ Grafana (Dashboards)            │  │                │ │
│  │  │  │ Port: 3000                      │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  │  ┌─────────────────────────────────┐  │                │ │
│  │  │  │ Apache Guacamole (Web RDP/SSH)  │  │                │ │
│  │  │  │ Port: 8080                      │  │                │ │
│  │  │  └─────────────────────────────────┘  │                │ │
│  │  └───────────────────────────────────────┘                │ │
│  │                                                             │ │
│  │  Windows Subnet (10.0.2.0/24)                             │ │
│  │  ┌───────────────────────────────────────┐                │ │
│  │  │  Windows Server 2022 (Standard_D4s_v3)│                │ │
│  │  │  4 vCPU | 16 GB RAM | 512 GB SSD      │                │ │
│  │  ├───────────────────────────────────────┤                │ │
│  │  │  💾 SQL Server 2022 (Native)          │                │ │
│  │  │  - Developer Edition                  │                │ │
│  │  │  - SSMS Installed                     │                │ │
│  │  │  - Optional comparison to containers  │                │ │
│  │  └───────────────────────────────────────┘                │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  🌐 Public IP: Static (Linux VM only)                          │
│  🔒 NSG: SSH, HTTP (8080), Grafana (3000), Prometheus (9090)  │
│  🔒 NSG: RDP from Linux subnet only (via Guacamole)           │
└─────────────────────────────────────────────────────────────────┘
```

### Design Principles

- **Container-First**: SQL Server runs in Docker containers for portability and consistency
- **Hybrid Architecture**: Linux containers + Windows VM for comparison and SSMS access
- **Cost-Optimized**: Single-host multi-container design reduces infrastructure costs
- **Production-Like**: Simulates real HA/DR scenarios without production complexity
- **Observable**: Built-in monitoring with Prometheus and Grafana
- **Accessible**: Browser-based access via Guacamole (no VPN/Bastion required)

---

## 📋 Prerequisites

### Required Software

| Software | Minimum Version | Purpose |
|----------|----------------|---------|
| **Terraform** | ≥ 1.5.0 | Infrastructure provisioning |
| **Azure CLI** | ≥ 2.50.0 | Azure authentication |
| **SSH Key** | RSA 2048+ | Linux VM access |

### Azure Requirements

- **Subscription**: Pay-as-you-go or Dev/Test
- **Quota**: 12+ vCPUs (DSv3 family) in target region
- **Permissions**: Contributor role on subscription or resource group
- **Budget**: ~$700/month (24/7) or ~$300/month (8hrs/day with auto-shutdown)

### Local Setup

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Authenticate
az login
az account set --subscription "your-subscription-name"

# Generate SSH key (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/adrian207/azure-sql-docker-demos.git
cd azure-sql-docker-demos
```

### 2. Configure Variables

```bash
cd terraform

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# Admin credentials
admin_username = "sqladmin"
admin_password = "YourComplexPassword123!"  # Min 12 chars, complex
sql_sa_password = "YourSQLPassword123!"     # Min 8 chars, complex

# Network security (IMPORTANT: Restrict to your IP!)
allowed_ip_ranges = ["YOUR.PUBLIC.IP/32"]

# Optional: Cost optimization
auto_shutdown_enabled = true
auto_shutdown_time    = "1900"  # 7 PM shutdown
EOF
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply -auto-approve
```

### 4. Access Services

After deployment, Terraform outputs connection details:

```bash
# Get connection information
terraform output

# Example output:
linux_public_ip = "20.123.45.67"
guacamole_url   = "http://20.123.45.67:8080/guacamole"
grafana_url     = "http://20.123.45.67:3000"
prometheus_url  = "http://20.123.45.67:9090"
```

**Access URLs:**
- 🖥️ **Guacamole**: `http://<linux_public_ip>:8080/guacamole` (username: `guacadmin`)
- 📊 **Grafana**: `http://<linux_public_ip>:3000` (username: `admin`)
- 📈 **Prometheus**: `http://<linux_public_ip>:9090`

### 5. Connect to SQL Server

**From SSMS (on Windows VM via Guacamole):**
```
Server: <linux_private_ip>,1433
Login: sa
Password: <sql_sa_password>
```

**From Linux VM (SSH):**
```bash
ssh sqladmin@<linux_public_ip>
docker exec -it sql-primary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourSQLPassword123!'
```

---

## 🎓 SQL Server Demos

This project supports three main high availability demonstration scenarios:

### Demo 1: Log Shipping 📦

**Branch:** `feat/sql-log-shipping`

**Scenario:** Traditional backup-based warm standby

- Primary database takes transaction log backups every 15 minutes
- Secondary database restores logs in standby mode
- Manual failover process demonstrated
- **Use Case:** Simple DR, reporting offload, cost-effective HA

**Setup:**
```bash
git checkout feat/sql-log-shipping
cd docker/log-shipping
docker-compose up -d
./configure-log-shipping.sh
```

---

### Demo 2: Transactional Replication 🔄

**Branch:** `feat/sql-transactional-replication`

**Scenario:** Real-time one-way data synchronization

- Publisher (primary) pushes changes to subscriber (secondary)
- Near real-time replication latency (<5 seconds)
- Table-level or database-level replication
- **Use Case:** Data distribution, reporting, data warehousing

**Setup:**
```bash
git checkout feat/sql-transactional-replication
cd docker/replication
docker-compose up -d
./setup-replication.sh
```

---

### Demo 3: Always On Availability Groups ⚡

**Branch:** `feat/sql-always-on-ag`

**Scenario:** Enterprise-grade automatic failover

- 3-node cluster (Primary, Secondary, Witness)
- Automatic failover detection and promotion
- Synchronous or asynchronous commit modes
- **Use Case:** Mission-critical databases, zero data loss, RTO < 30 seconds

**Requirements:** 
- 3 SQL Server containers (requires D16s_v3 or larger)
- SQL Server Enterprise Edition (or Developer for non-prod)

**Setup:**
```bash
git checkout feat/sql-always-on-ag
cd docker/always-on
docker-compose up -d
./configure-ag.sh
```

---

## 📊 Cost Analysis

Detailed cost breakdown with optimization strategies:

### Monthly Costs (West US 2)

| Configuration | 24/7 Cost | 8hr/day Cost | Savings |
|--------------|-----------|--------------|---------|
| **Standard** (D8s_v3 + D4s_v3) | $696 | $309 | 56% |
| **Optimized** (D4s_v3 + D2s_v3) | $291 | $145 | 50% |
| **Reserved Instances** (1-year) | $346 | - | 30% |

**Full cost analysis:** See [COST_BREAKDOWN.md](./COST_BREAKDOWN.md)

**VMs vs Containers comparison:** See [COST_ANALYSIS_CONTAINERS.md](./COST_ANALYSIS_CONTAINERS.md)

### Cost Optimization Tips

```hcl
# In terraform.tfvars

# 1. Enable auto-shutdown (56% savings)
auto_shutdown_enabled = true
auto_shutdown_time    = "1900"  # 7 PM

# 2. Use smaller VMs for testing
linux_vm_size   = "Standard_D4s_v3"  # Instead of D8s_v3
windows_vm_size = "Standard_D2s_v3"  # Instead of D4s_v3

# 3. Reduce disk sizes
linux_data_disk_size_gb   = 256  # Instead of 512
windows_data_disk_size_gb = 256  # Instead of 512

# 4. Deploy only Linux VM
deploy_windows_native_sql = false
```

---

## 📁 Project Structure

```
azure-sql-docker-demos/
├── terraform/               # Infrastructure as Code
│   ├── main.tf             # Provider and resource group
│   ├── network.tf          # VNet, subnets, NSGs
│   ├── linux-vm.tf         # Rocky Linux VM (TBD)
│   ├── windows-vm.tf       # Windows Server VM (TBD)
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values (TBD)
│   └── terraform.tfvars    # Your configuration (create this)
│
├── docker/                 # Container configurations (TBD)
│   ├── log-shipping/       # Log shipping demo
│   ├── replication/        # Replication demo
│   └── always-on/          # Always On AG demo
│
├── monitoring/             # Observability stack (TBD)
│   ├── prometheus/         # Metrics collection
│   ├── grafana/            # Dashboards
│   └── exporters/          # SQL Server exporter
│
├── ansible/                # Configuration automation (TBD)
│   ├── playbooks/          # Setup playbooks
│   └── roles/              # Reusable roles
│
├── windows/                # Windows-specific configs (TBD)
│   ├── install-ssms.ps1    # SQL Server Management Studio
│   └── configure-sql.ps1   # Native SQL Server setup
│
├── COST_BREAKDOWN.md       # Detailed cost analysis
├── COST_ANALYSIS_CONTAINERS.md  # VMs vs Containers comparison
├── README.md               # This file
└── .gitignore              # Git ignore patterns
```

---

## 🔧 Configuration

### Terraform Variables

Key configuration options in `terraform.tfvars`:

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | `sql-docker-demo` | Resource naming prefix |
| `location` | `westus2` | Azure region |
| `linux_vm_size` | `Standard_D8s_v3` | Linux VM SKU (8 vCPU, 32 GB) |
| `windows_vm_size` | `Standard_D4s_v3` | Windows VM SKU (4 vCPU, 16 GB) |
| `allowed_ip_ranges` | `["0.0.0.0/0"]` | ⚠️ IPs allowed to access services |
| `sql_server_edition` | `Developer` | SQL Server edition |
| `auto_shutdown_enabled` | `true` | Enable nightly VM shutdown |
| `deploy_windows_native_sql` | `true` | Deploy SQL on Windows VM |

**Full variable reference:** See [terraform/variables.tf](./terraform/variables.tf)

---

## 🛡️ Security Considerations

### Network Security

```hcl
# IMPORTANT: Restrict access to your IP only!
allowed_ip_ranges = ["YOUR.PUBLIC.IP.ADDRESS/32"]

# Never use in production:
allowed_ip_ranges = ["0.0.0.0/0"]  # ❌ Open to internet
```

### Best Practices Implemented

- ✅ **No public Windows RDP**: Access only via Guacamole from Linux VM
- ✅ **SQL Server isolated**: Only accessible from VNet or authorized IPs
- ✅ **Sensitive variables**: Passwords marked `sensitive` in Terraform
- ✅ **NSG rules**: Least-privilege network access
- ⚠️ **SSH key recommended**: Better than password authentication

### Production Hardening (Not Included)

For production use, consider:

- 🔐 Azure Bastion instead of public IP
- 🔑 Azure Key Vault for secrets
- 🛡️ Azure Firewall or NVA
- 📊 Azure Monitor and Log Analytics
- 🔍 Microsoft Defender for Cloud
- 🌐 Private endpoints for SQL Server
- 🔐 Managed Identity for authentication

---

## 📖 Documentation

- [COST_BREAKDOWN.md](./COST_BREAKDOWN.md) - Detailed Azure cost analysis
- [COST_ANALYSIS_CONTAINERS.md](./COST_ANALYSIS_CONTAINERS.md) - VMs vs Containers comparison
- [Terraform Variables](./terraform/variables.tf) - All configuration options

**External Resources:**
- [SQL Server on Linux Containers](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [SQL Server High Availability](https://learn.microsoft.com/en-us/sql/database-engine/sql-server-business-continuity-dr)
- [Azure VM Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

---

## 🧪 Testing & Validation

### Smoke Tests

After deployment, verify services:

```bash
# 1. SSH to Linux VM
ssh sqladmin@<linux_public_ip>

# 2. Check Docker containers
docker ps

# Expected output: sql-primary, sql-secondary, prometheus, grafana, guacamole

# 3. Test SQL connection
docker exec -it sql-primary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourPassword'
1> SELECT @@VERSION;
2> GO

# 4. Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# 5. Access Grafana
curl http://localhost:3000/api/health
```

### Failover Testing

```bash
# Simulate primary failure
docker stop sql-primary

# Verify secondary is accessible
docker exec -it sql-secondary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa

# Restore primary
docker start sql-primary
```

---

## 🔄 Management Operations

### Start Environment

```bash
# Start all VMs
cd terraform
terraform apply -auto-approve

# Or manually via Azure CLI
az vm start --resource-group <rg-name> --name <vm-name>
```

### Stop Environment (Save Costs)

```bash
# Deallocate VMs (stops billing)
az vm deallocate --resource-group <rg-name> --name <linux-vm-name>
az vm deallocate --resource-group <rg-name> --name <windows-vm-name>
```

### Destroy Everything

```bash
cd terraform
terraform destroy -auto-approve

# Confirm deletion in Azure Portal
az group delete --name <resource-group-name> --yes
```

### Backup SQL Databases

```bash
# From Linux VM
docker exec -it sql-primary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'password' \
  -Q "BACKUP DATABASE [YourDB] TO DISK='/var/opt/mssql/backup/yourdb.bak'"

# Copy backup to local machine
scp sqladmin@<linux_public_ip>:/var/opt/mssql/backup/yourdb.bak ./
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Terraform deployment fails with quota error

**Solution:**
```bash
# Check quota
az vm list-usage --location westus2 --query "[?name.value=='standardDSv3Family']"

# Request quota increase
az support tickets create --issue-type quota
```

#### Issue: Cannot connect to SQL Server containers

**Solution:**
```bash
# Check container logs
docker logs sql-primary

# Verify SQL is listening
docker exec sql-primary netstat -an | grep 1433

# Test from Linux VM
telnet localhost 1433
```

#### Issue: Guacamole not accessible

**Solution:**
```bash
# Check NSG rules allow your IP
az network nsg rule list --nsg-name sql-docker-demo-linux-nsg --resource-group <rg-name>

# Verify container is running
docker ps | grep guacamole

# Check logs
docker logs guacamole
```

#### Issue: Auto-shutdown not working

**Solution:**
```bash
# Verify schedule exists
az vm list --resource-group <rg-name> --show-details --query "[].{Name:name, PowerState:powerState}"

# Check DevTest Labs schedule
az devtest lab schedule show --lab-name <lab-name> --name LabVmsShutdown
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

```bash
# Format Terraform code
terraform fmt -recursive

# Validate configuration
terraform validate

# Security scanning
tfsec .

# Linting
tflint
```

---

## 👤 Author

**Adrian Johnson**
- Email: [adrian207@gmail.com](mailto:adrian207@gmail.com)
- GitHub: [@adrian207](https://github.com/adrian207)
- Repository: [azure-sql-docker-demos](https://github.com/adrian207/azure-sql-docker-demos)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Adrian Johnson

---

## 🙏 Acknowledgments

- **Microsoft SQL Server** - Database engine
- **Docker** - Container runtime
- **Terraform** - Infrastructure as Code
- **Prometheus & Grafana** - Monitoring stack
- **Apache Guacamole** - Clientless remote desktop
- **Rocky Linux** - Enterprise Linux distribution

---

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/adrian207/azure-sql-docker-demos/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/adrian207/azure-sql-docker-demos/discussions)
- **Email**: [adrian207@gmail.com](mailto:adrian207@gmail.com)
- **SQL Server Documentation**: [Microsoft Learn](https://learn.microsoft.com/en-us/sql/)
- **Azure Support**: [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

---

<div align="center">

**Built with ❤️ for SQL Server and container enthusiasts**

[View on GitHub](https://github.com/adrian207/azure-sql-docker-demos) • [Report Issue](https://github.com/adrian207/azure-sql-docker-demos/issues) • [Request Feature](https://github.com/adrian207/azure-sql-docker-demos/issues/new)

**Created and Maintained by Adrian Johnson**  
📧 [adrian207@gmail.com](mailto:adrian207@gmail.com) | 💻 [@adrian207](https://github.com/adrian207)

⭐ **Star this repo if you find it helpful!** ⭐

</div>

