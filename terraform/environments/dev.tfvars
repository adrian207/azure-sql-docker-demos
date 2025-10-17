# Development Environment Configuration
# Purpose: Daily development and testing
# Cost: ~$150-200/month with auto-shutdown

#==============================================================================
# ENVIRONMENT
#==============================================================================
project_name = "sql-docker-demo"
environment  = "dev"
location     = "westus2"  # Or your preferred region

#==============================================================================
# COMPUTE - Cost-Optimized for Dev
#==============================================================================

# Linux VM - Smaller for dev work
linux_vm_size = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM
# vs prod: Standard_D8s_v3 (8 vCPU, 32 GB RAM)

# Windows VM - Minimum viable size
windows_vm_size = "Standard_D2s_v3"  # 2 vCPU, 8 GB RAM
# vs prod: Standard_D4s_v3 (4 vCPU, 16 GB RAM)

#==============================================================================
# STORAGE - Smaller Disks
#==============================================================================
linux_disk_size_gb      = 256  # vs prod: 512
linux_data_disk_size_gb = 256  # vs prod: 512

windows_disk_size_gb      = 128  # vs prod: 256
windows_data_disk_size_gb = 256  # vs prod: 512

#==============================================================================
# COST OPTIMIZATION - Aggressive
#==============================================================================
auto_shutdown_enabled = true
auto_shutdown_time    = "1800"  # 6 PM - Earlier than prod
auto_shutdown_timezone = "Pacific Standard Time"

#==============================================================================
# FEATURES - Dev-Specific
#==============================================================================
deploy_windows_native_sql     = false  # Skip for dev (use containers only)
deploy_windows_container_sql  = false
enable_prometheus             = true
enable_grafana                = true

#==============================================================================
# SQL SERVER
#==============================================================================
sql_server_edition = "Developer"  # Free for non-prod

#==============================================================================
# NETWORK SECURITY - Must Configure!
#==============================================================================
# !!! REPLACE WITH YOUR IP !!!
# Get your IP: curl ifconfig.me
allowed_ip_ranges = ["YOUR_IP_HERE/32"]  # ⚠️ CHANGE THIS!

# Example:
# allowed_ip_ranges = ["203.0.113.42/32"]

#==============================================================================
# CREDENTIALS - Required (use strong passwords!)
#==============================================================================
admin_username = "sqladmin"

# Generate strong passwords:
# openssl rand -base64 24

admin_password           = ""  # REQUIRED: Set your Windows admin password
sql_sa_password          = ""  # REQUIRED: Set your SQL SA password
guacamole_admin_password = ""  # REQUIRED: Set your Guacamole password

#==============================================================================
# TAGS
#==============================================================================
tags = {
  Project     = "SQL-Docker-Demos"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
  CostCenter  = "Engineering"
  Purpose     = "Development and Testing"
  AutoShutdown = "Enabled"
}

#==============================================================================
# NOTES
#==============================================================================
# Expected Monthly Cost: ~$145/month (8 hours/day with auto-shutdown)
# Deployment Time: ~10-15 minutes
# Use Case: Daily development, feature testing, learning

