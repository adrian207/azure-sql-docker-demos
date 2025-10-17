# Azure SQL Server Docker Demos - Windows VM Configuration
# Author: Adrian Johnson <adrian207@gmail.com>
# GitHub: https://github.com/adrian207/azure-sql-docker-demos

# Windows Server VM for SQL Server Management

# Data disk for SQL Server data
resource "azurerm_managed_disk" "windows_data" {
  count                = var.deploy_windows_native_sql ? 1 : 0
  name                 = "${var.project_name}-windows-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.windows_data_disk_size_gb
  tags                 = var.tags
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "windows" {
  name                = "${var.project_name}-windows-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.windows_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.windows.id,
  ]

  os_disk {
    name                 = "${var.project_name}-windows-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.windows_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  # Enable automatic Windows updates
  patch_mode                                             = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = false

  boot_diagnostics {
    storage_account_uri = null # Uses managed storage
  }
}

# Attach data disk to Windows VM (if deploying native SQL)
resource "azurerm_virtual_machine_data_disk_attachment" "windows_data" {
  count              = var.deploy_windows_native_sql ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.windows_data[0].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows.id
  lun                = 0
  caching            = "ReadOnly" # SQL data disk best practice
}

# VM Extension to configure Windows
resource "azurerm_virtual_machine_extension" "windows_config" {
  name                 = "ConfigureWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags

  settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Unrestricted -Command "
        # Enable RDP
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0;
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop';
        
        # Configure firewall for SQL Server
        New-NetFirewallRule -DisplayName 'SQL Server' -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue;
        
        # Disable IE Enhanced Security
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0;
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0;
        
        # Install Chocolatey
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
        
        # Install useful tools
        choco install -y googlechrome;
        choco install -y notepadplusplus;
        choco install -y 7zip;
        
        # Install SQL Server Management Studio (SSMS)
        choco install -y sql-server-management-studio;
        
        # Create SSMS desktop shortcut
        `$WshShell = New-Object -comObject WScript.Shell;
        `$Shortcut = `$WshShell.CreateShortcut('C:\Users\Public\Desktop\SSMS.lnk');
        `$Shortcut.TargetPath = 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe';
        `$Shortcut.Save();
      "
    EOT
  })

  depends_on = [azurerm_windows_virtual_machine.windows]
}

# Optional: Install SQL Server natively on Windows
resource "azurerm_virtual_machine_extension" "windows_sql" {
  count                = var.deploy_windows_native_sql ? 1 : 0
  name                 = "InstallSQLServer"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags

  settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Unrestricted -Command "
        # Download SQL Server 2022 Developer Edition
        `$sqlUrl = 'https://go.microsoft.com/fwlink/?linkid=2215158';
        `$sqlInstaller = 'C:\Temp\SQLServer2022-DEV-x64-ENU.exe';
        New-Item -Path C:\Temp -ItemType Directory -Force;
        
        Write-Host 'Downloading SQL Server 2022 Developer Edition...';
        Invoke-WebRequest -Uri `$sqlUrl -OutFile `$sqlInstaller -UseBasicParsing;
        
        # Extract installer
        Write-Host 'Extracting SQL Server installer...';
        Start-Process -FilePath `$sqlInstaller -ArgumentList '/Q', '/X:C:\Temp\SQLServer' -Wait;
        
        # Install SQL Server
        Write-Host 'Installing SQL Server...';
        `$configFile = @'
[OPTIONS]
ACTION=\"Install\"
FEATURES=SQLENGINE,FULLTEXT,CONN
INSTANCENAME=\"MSSQLSERVER\"
SQLSYSADMINACCOUNTS=\"${var.admin_username}\"
SECURITYMODE=\"SQL\"
SAPWD=\"${var.sql_sa_password}\"
TCPENABLED=\"1\"
NPENABLED=\"0\"
BROWSERSVCSTARTUPTYPE=\"Automatic\"
SQLSVCACCOUNT=\"NT AUTHORITY\SYSTEM\"
AGTSVCACCOUNT=\"NT AUTHORITY\SYSTEM\"
AGTSVCSTARTUPTYPE=\"Automatic\"
IACCEPTSQLSERVERLICENSETERMS=\"True\"
INSTALLSQLDATADIR=\"F:\SQLData\"
SQLUSERDBDIR=\"F:\SQLData\"
SQLUSERDBLOGDIR=\"F:\SQLLog\"
SQLTEMPDBDIR=\"F:\SQLTemp\"
SQLTEMPDBLOGDIR=\"F:\SQLTemp\"
'@;
        
        `$configFile | Out-File -FilePath 'C:\Temp\ConfigurationFile.ini' -Encoding ASCII;
        
        # Format and mount data disk
        Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'SQLData' -Confirm:`$false;
        
        # Create directories
        New-Item -Path F:\SQLData -ItemType Directory -Force;
        New-Item -Path F:\SQLLog -ItemType Directory -Force;
        New-Item -Path F:\SQLTemp -ItemType Directory -Force;
        
        # Run SQL Server installation
        Start-Process -FilePath 'C:\Temp\SQLServer\setup.exe' -ArgumentList '/ConfigurationFile=C:\Temp\ConfigurationFile.ini' -Wait;
        
        Write-Host 'SQL Server installation complete!';
      "
    EOT
  })

  depends_on = [
    azurerm_virtual_machine_extension.windows_config,
    azurerm_virtual_machine_data_disk_attachment.windows_data
  ]
}

# Auto-shutdown schedule for Windows VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "windows" {
  count              = var.auto_shutdown_enabled ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.windows.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

