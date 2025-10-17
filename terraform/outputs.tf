# Azure SQL Server Docker Demos - Outputs
# Author: Adrian Johnson <adrian207@gmail.com>
# GitHub: https://github.com/adrian207/azure-sql-docker-demos

# Network Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

# Linux VM Outputs
output "linux_public_ip" {
  description = "Public IP address of the Linux VM"
  value       = azurerm_public_ip.linux.ip_address
}

output "linux_private_ip" {
  description = "Private IP address of the Linux VM"
  value       = azurerm_network_interface.linux.private_ip_address
}

# Windows VM Outputs
output "windows_private_ip" {
  description = "Private IP address of the Windows VM"
  value       = azurerm_network_interface.windows.private_ip_address
}

# Service URLs
output "guacamole_url" {
  description = "URL to access Apache Guacamole"
  value       = "http://${azurerm_public_ip.linux.ip_address}:8080/guacamole"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${azurerm_public_ip.linux.ip_address}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${azurerm_public_ip.linux.ip_address}:9090"
}

# Connection Instructions
output "connection_instructions" {
  description = "Instructions for connecting to the environment"
  value       = <<-EOT
    ==========================================
    Azure SQL Docker Demos - Connection Info
    ==========================================
    
    🌐 PUBLIC ACCESS:
    -----------------
    Linux VM Public IP:    ${azurerm_public_ip.linux.ip_address}
    
    Web Services:
    - Guacamole (Web UI):  http://${azurerm_public_ip.linux.ip_address}:8080/guacamole
    - Grafana:             http://${azurerm_public_ip.linux.ip_address}:3000
    - Prometheus:          http://${azurerm_public_ip.linux.ip_address}:9090
    
    🔐 SSH ACCESS:
    --------------
    ssh ${var.admin_username}@${azurerm_public_ip.linux.ip_address}
    
    🖥️ PRIVATE IPs (Internal):
    ---------------------------
    Linux VM:    ${azurerm_network_interface.linux.private_ip_address}
    Windows VM:  ${azurerm_network_interface.windows.private_ip_address}
    
    💾 SQL SERVER CONTAINERS:
    -------------------------
    Primary:     ${azurerm_network_interface.linux.private_ip_address}:1433
    Secondary:   ${azurerm_network_interface.linux.private_ip_address}:1434
    Witness:     ${azurerm_network_interface.linux.private_ip_address}:1435
    
    Connection String (SSMS):
    Server:   ${azurerm_network_interface.linux.private_ip_address},1433
    Login:    sa
    Password: <sql_sa_password from tfvars>
    
    📊 MONITORING:
    --------------
    Grafana:     http://${azurerm_public_ip.linux.ip_address}:3000
    User:        admin
    Password:    admin (change on first login)
    
    Prometheus:  http://${azurerm_public_ip.linux.ip_address}:9090
    
    🖥️ REMOTE DESKTOP (via Guacamole):
    -----------------------------------
    1. Open: http://${azurerm_public_ip.linux.ip_address}:8080/guacamole
    2. Login: guacadmin / ${var.guacamole_admin_password}
    3. Connect to Windows VM via pre-configured RDP
    
    ⚡ NEXT STEPS:
    --------------
    1. SSH into Linux VM
    2. Run: docker ps
    3. Configure SQL demos (see README.md)
    4. Access Grafana for monitoring
    
    ==========================================
  EOT
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    resource_group   = azurerm_resource_group.main.name
    location         = azurerm_resource_group.main.location
    linux_public_ip  = azurerm_public_ip.linux.ip_address
    linux_private_ip = azurerm_network_interface.linux.private_ip_address
    windows_private_ip = azurerm_network_interface.windows.private_ip_address
    guacamole_url    = "http://${azurerm_public_ip.linux.ip_address}:8080/guacamole"
    grafana_url      = "http://${azurerm_public_ip.linux.ip_address}:3000"
    prometheus_url   = "http://${azurerm_public_ip.linux.ip_address}:9090"
  }
}

