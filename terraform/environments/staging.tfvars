# Staging Environment Configuration
# Purpose: Pre-production testing and validation
# Cost: ~$250-350/month with auto-shutdown

#==============================================================================
# ENVIRONMENT
#==============================================================================
project_name = "sql-docker-demo"
environment  = "staging"
location     = "westus2"

#==============================================================================
# COMPUTE - Production-Like Performance
#==============================================================================

# Linux VM - Same as prod for accurate testing
linux_vm_size = "Standard_D8s_v3"  # 8 vCPU, 32 GB RAM

# Windows VM - Same as prod
windows_vm_size = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM

#==============================================================================
# STORAGE - Production-Like
#==============================================================================
linux_disk_size_gb      = 512
linux_data_disk_size_gb = 512

windows_disk_size_gb      = 256
windows_data_disk_size_gb = 512

#==============================================================================
# COST OPTIMIZATION - Moderate
#==============================================================================
auto_shutdown_enabled = true
auto_shutdown_time    = "2000"  # 8 PM - Later for extended testing
auto_shutdown_timezone = "Pacific Standard Time"

#==============================================================================
# FEATURES - Test All Features
#==============================================================================
deploy_windows_native_sql     = true   # Test both native and containers
deploy_windows_container_sql  = false
enable_prometheus             = true
enable_grafana                = true

#==============================================================================
# SQL SERVER
#==============================================================================
sql_server_edition = "Developer"  # Or "Standard" if testing licensing

#==============================================================================
# NETWORK SECURITY
#==============================================================================
# Allow office/VPN IPs
allowed_ip_ranges = [
  "YOUR_OFFICE_IP/32",
  "YOUR_VPN_RANGE/24"
]

#==============================================================================
# CREDENTIALS
#==============================================================================
admin_username = "sqladmin"

# Use different passwords than dev!
admin_password           = ""  # REQUIRED
sql_sa_password          = ""  # REQUIRED
guacamole_admin_password = ""  # REQUIRED

#==============================================================================
# TAGS
#==============================================================================
tags = {
  Project     = "SQL-Docker-Demos"
  Environment = "Staging"
  ManagedBy   = "Terraform"
  Owner       = "QA-Team"
  CostCenter  = "Engineering"
  Purpose     = "Pre-Production Testing"
  AutoShutdown = "Enabled"
  Compliance  = "Non-Production"
}

#==============================================================================
# NOTES
#==============================================================================
# Expected Monthly Cost: ~$309/month (12 hours/day with auto-shutdown)
# Deployment Time: ~15 minutes
# Use Case: Integration testing, UAT, performance testing
# Data Retention: 30 days

