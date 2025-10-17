# Windows Server Configuration

This directory contains PowerShell scripts and configurations for the Windows Server VM.

## What Gets Installed Automatically

When the Windows VM deploys, it automatically installs:

✅ **SQL Server Management Studio (SSMS)** - Latest version  
✅ **Google Chrome** - For better web browsing  
✅ **Notepad++** - Better text editor  
✅ **7-Zip** - File compression  

## Access Windows VM

### Via Guacamole (Recommended)

1. Open: `http://<linux-public-ip>:8080/guacamole`
2. Login: `guacadmin` / `guacadmin` (change password!)
3. Click on "Windows Server 2022" connection
4. Use Windows credentials from your `terraform.tfvars`

### Via Direct RDP (Not Exposed by Default)

The Windows VM has **no public IP** for security. If you need direct RDP:

```bash
# Option 1: SSH tunnel through Linux VM
ssh -L 3389:<windows-private-ip>:3389 sqladmin@<linux-public-ip>
# Then RDP to localhost:3389

# Option 2: Deploy Azure Bastion (adds ~$140/month)
```

## Connecting to SQL Server Containers

From the Windows VM, use SSMS to connect to containers running on the Linux VM:

### Connection Details

**Primary SQL Server:**
```
Server: <linux-private-ip>,1433
Authentication: SQL Server Authentication
Login: sa
Password: <sql_sa_password from terraform.tfvars>
```

**Secondary SQL Server:**
```
Server: <linux-private-ip>,1434
Authentication: SQL Server Authentication
Login: sa
Password: <sql_sa_password from terraform.tfvars>
```

**Witness SQL Server:**
```
Server: <linux-private-ip>,1435
Authentication: SQL Server Authentication
Login: sa
Password: <sql_sa_password from terraform.tfvars>
```

## Optional: Native SQL Server Installation

If you set `deploy_windows_native_sql = true` in terraform.tfvars, the VM also installs SQL Server 2022 Developer Edition natively on Windows.

**Native SQL Connection:**
```
Server: localhost  (or . or 127.0.0.1)
Authentication: Windows Authentication (or SQL: sa/<password>)
```

**SQL Server directories:**
- Data: `F:\SQLData`
- Logs: `F:\SQLLog`
- TempDB: `F:\SQLTemp`

## Post-Deployment Steps

### 1. Change Default Passwords

```powershell
# In PowerShell on Windows VM
# Change local admin password
net user <admin-username> <new-password>
```

### 2. Configure Windows Firewall

```powershell
# Allow SQL Server (if native SQL installed)
New-NetFirewallRule -DisplayName "SQL Server" `
  -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

# Allow SSMS to connect outbound
New-NetFirewallRule -DisplayName "SSMS Outbound" `
  -Direction Outbound -Protocol TCP -RemotePort 1433-1435 -Action Allow
```

### 3. Install Additional Tools (Optional)

```powershell
# Azure Data Studio (modern SQL tool)
choco install azure-data-studio

# SQL Server Data Tools
choco install ssdt17

# PowerShell SQL Server module
Install-Module -Name SqlServer -Force

# Git for Windows
choco install git
```

## Useful PowerShell Scripts

### Test SQL Connectivity

```powershell
# Test-SQLConnection.ps1
$serverName = "10.0.1.4,1433"  # Replace with Linux private IP
$connectionString = "Server=$serverName;User Id=sa;Password=YourPassword;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "✅ Connection successful!" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Host "❌ Connection failed: $_" -ForegroundColor Red
}
```

### Query All SQL Instances

```powershell
# Query-AllInstances.ps1
$linuxIP = "10.0.1.4"  # Replace with Linux private IP
$password = "YourSQLPassword"

$instances = @(
    @{Name="Primary"; Port=1433},
    @{Name="Secondary"; Port=1434},
    @{Name="Witness"; Port=1435}
)

foreach ($instance in $instances) {
    Write-Host "`n=== $($instance.Name) ($linuxIP,$($instance.Port)) ===" -ForegroundColor Cyan
    
    $query = "SELECT @@SERVERNAME AS ServerName, @@VERSION AS Version"
    $result = Invoke-Sqlcmd -ServerInstance "$linuxIP,$($instance.Port)" `
                            -Username sa -Password $password -Query $query
    
    $result | Format-Table -AutoSize
}
```

## Troubleshooting

### Cannot connect to Linux SQL containers

```powershell
# Test network connectivity
Test-NetConnection -ComputerName <linux-private-ip> -Port 1433

# Check if SQL Server is reachable
telnet <linux-private-ip> 1433

# Verify NSG rules allow traffic from Windows subnet
```

### SSMS not installed

```powershell
# Manually install SSMS
choco install sql-server-management-studio -y

# Or download directly
Start-Process "https://aka.ms/ssmsfullsetup"
```

### Performance issues

```powershell
# Check VM resources
Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object @{N="RAM (GB)";E={$_.TotalPhysicalMemory/1GB}}

# Monitor resource usage
perfmon

# Check disk performance
Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, Size, OperationalStatus
```

## Security Best Practices

⚠️ **For demo environments only!**

For production:
- ✅ Use Azure Bastion instead of public access
- ✅ Enable Windows Defender
- ✅ Configure Windows Update
- ✅ Use Azure Key Vault for credentials
- ✅ Enable disk encryption
- ✅ Implement least privilege access
- ✅ Enable audit logging
- ✅ Regular patching and updates

## Additional Resources

- [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/)
- [Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/)
- [PowerShell SqlServer Module](https://learn.microsoft.com/en-us/powershell/module/sqlserver/)

