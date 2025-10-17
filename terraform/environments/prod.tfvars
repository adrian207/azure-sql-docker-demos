# Production Environment Configuration
# Purpose: Production workloads (if applicable)
# Cost: ~$700-900/month (24/7 operation)

#==============================================================================
# ENVIRONMENT
#==============================================================================
project_name = "sql-docker-demo"
environment  = "prod"
location     = "eastus"  # Consider multi-region for prod

#==============================================================================
# COMPUTE - High Performance
#==============================================================================

# Linux VM - Maximum performance for production
linux_vm_size = "Standard_E8s_v3"  # 8 vCPU, 64 GB RAM (memory-optimized)
# Alternative: Standard_D16s_v3 for even more power

# Windows VM - Full-featured
windows_vm_size = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM

#==============================================================================
# STORAGE - High Performance & Redundancy
#==============================================================================
linux_disk_size_gb      = 512
linux_data_disk_size_gb = 1024  # Larger for production data

windows_disk_size_gb      = 256
windows_data_disk_size_gb = 1024

#==============================================================================
# COST OPTIMIZATION - Minimal (Availability Priority)
#==============================================================================
auto_shutdown_enabled = false  # Never shutdown production!
auto_shutdown_time    = "2300"  # Only if absolutely necessary
auto_shutdown_timezone = "Eastern Standard Time"

#==============================================================================
# FEATURES - Full Production Stack
#==============================================================================
deploy_windows_native_sql     = true   # Deploy both for comparison
deploy_windows_container_sql  = false
enable_prometheus             = true
enable_grafana                = true

#==============================================================================
# SQL SERVER
#==============================================================================
sql_server_edition = "Standard"  # Or "Enterprise" for production licensing
# Note: Developer edition NOT licensed for production!

#==============================================================================
# NETWORK SECURITY - Strict
#==============================================================================
# Whitelist specific IPs only - NO 0.0.0.0/0!
allowed_ip_ranges = [
  "CORPORATE_OFFICE_IP/32",
  "VPN_GATEWAY_IP/32",
  "MONITORING_SYSTEM_IP/32"
]

# Consider: Add Azure Firewall or NVA for production

#==============================================================================
# CREDENTIALS
#==============================================================================
admin_username = "sqladmin"

# CRITICAL: Use Azure Key Vault in production!
# These should reference Key Vault secrets, not plain text

admin_password           = ""  # REQUIRED: Strong password (16+ chars)
sql_sa_password          = ""  # REQUIRED: Strong password (16+ chars)
guacamole_admin_password = ""  # REQUIRED: Strong password (16+ chars)

#==============================================================================
# TAGS
#==============================================================================
tags = {
  Project      = "SQL-Docker-Demos"
  Environment  = "Production"
  ManagedBy    = "Terraform"
  Owner        = "Platform-Team"
  CostCenter   = "Operations"
  Purpose      = "Production Workload"
  AutoShutdown = "Disabled"
  Compliance   = "Required"
  Criticality  = "High"
  SLA          = "99.9%"
  Backup       = "Required"
}

#==============================================================================
# PRODUCTION REQUIREMENTS
#==============================================================================
# Before deploying to production:
# 
# ✅ SECURITY:
# - [ ] Integrate Azure Key Vault for secrets
# - [ ] Enable disk encryption
# - [ ] Add TLS/HTTPS for all services
# - [ ] Configure Azure Security Center
# - [ ] Enable NSG flow logs
# - [ ] Add Azure Firewall or NVA
# - [ ] Implement private endpoints
# 
# ✅ AVAILABILITY:
# - [ ] Configure availability zones
# - [ ] Set up Azure Backup
# - [ ] Implement disaster recovery plan
# - [ ] Test failover procedures
# - [ ] Configure monitoring alerts
# 
# ✅ COMPLIANCE:
# - [ ] Enable audit logging
# - [ ] Configure Azure Policy
# - [ ] Implement resource locks
# - [ ] Document compliance procedures
# 
# ✅ OPERATIONS:
# - [ ] Set up 24/7 monitoring
# - [ ] Configure automated backups
# - [ ] Establish incident response plan
# - [ ] Create runbooks
# - [ ] Set up cost alerts

#==============================================================================
# NOTES
#==============================================================================
# Expected Monthly Cost: ~$896/month (24/7, reserved instances recommended)
# Deployment Time: ~20 minutes
# Use Case: Production workloads requiring high availability
# SLA Target: 99.9% uptime
# Data Retention: Per compliance requirements
# 
# ⚠️ WARNING: This configuration is for production use.
#             Ensure all security and compliance requirements are met!

