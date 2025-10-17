# Azure SQL Server Docker Demos - Linux VM Configuration
# Author: Adrian Johnson <adrian207@gmail.com>
# GitHub: https://github.com/adrian207/azure-sql-docker-demos

# Rocky Linux VM for SQL Server Containers

# Data disk for Docker volumes
resource "azurerm_managed_disk" "linux_data" {
  name                 = "${var.project_name}-linux-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.linux_data_disk_size_gb
  tags                 = var.tags
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "linux" {
  name                = "${var.project_name}-linux-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.linux_vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.linux.id,
  ]

  # SSH key authentication (recommended)
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  # Disable password authentication for security
  disable_password_authentication = true

  os_disk {
    name                 = "${var.project_name}-linux-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.linux_disk_size_gb
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-9"
    sku       = "rockylinux-9"
    version   = "latest"
  }

  # Cloud-init configuration
  custom_data = base64encode(templatefile("${path.module}/cloud-init-linux.yaml", {
    admin_username           = var.admin_username
    sql_sa_password          = var.sql_sa_password
    guacamole_admin_password = var.guacamole_admin_password
    windows_private_ip       = azurerm_network_interface.windows.private_ip_address
    enable_prometheus        = var.enable_prometheus
    enable_grafana           = var.enable_grafana
  }))

  boot_diagnostics {
    storage_account_uri = null # Uses managed storage
  }
}

# Attach data disk to Linux VM
resource "azurerm_virtual_machine_data_disk_attachment" "linux_data" {
  managed_disk_id    = azurerm_managed_disk.linux_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.linux.id
  lun                = 0
  caching            = "ReadWrite"
}

# Auto-shutdown schedule for Linux VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "linux" {
  count              = var.auto_shutdown_enabled ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.linux.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

