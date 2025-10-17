variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sql-docker-demo"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "sqladmin"
}

variable "admin_password" {
  description = "Admin password for Windows VM (min 12 chars, complex)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for Linux VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Linux VM Configuration
variable "linux_vm_size" {
  description = "Size of the Rocky Linux VM"
  type        = string
  default     = "Standard_D8s_v3" # 8 vCPU, 32 GB RAM
}

variable "linux_disk_size_gb" {
  description = "OS disk size for Linux VM in GB"
  type        = number
  default     = 512
}

variable "linux_data_disk_size_gb" {
  description = "Data disk size for Linux VM (Docker volumes)"
  type        = number
  default     = 512
}

# Windows VM Configuration
variable "windows_vm_size" {
  description = "Size of the Windows Server VM"
  type        = string
  default     = "Standard_D4s_v3" # 4 vCPU, 16 GB RAM
}

variable "windows_disk_size_gb" {
  description = "OS disk size for Windows VM in GB"
  type        = number
  default     = 256
}

variable "windows_data_disk_size_gb" {
  description = "Data disk size for Windows VM (SQL Server data)"
  type        = number
  default     = 512
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "linux_subnet_prefix" {
  description = "Subnet prefix for Linux VM"
  type        = string
  default     = "10.0.1.0/24"
}

variable "windows_subnet_prefix" {
  description = "Subnet prefix for Windows VM"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the environment (REQUIRED - get your IP: curl ifconfig.me)"
  type        = list(string)
  
  validation {
    condition     = length(var.allowed_ip_ranges) > 0 && !contains(var.allowed_ip_ranges, "0.0.0.0/0")
    error_message = "ERROR: You must specify your IP address. Never use 0.0.0.0/0! Get your IP: curl ifconfig.me"
  }
}

# SQL Server Configuration
variable "sql_sa_password" {
  description = "SQL Server SA password (min 8 chars, complex)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.sql_sa_password) >= 8
    error_message = "SQL SA password must be at least 8 characters long."
  }
}

variable "sql_server_edition" {
  description = "SQL Server edition (Developer, Express, Enterprise)"
  type        = string
  default     = "Developer"
}

# Monitoring Configuration
variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana dashboards"
  type        = bool
  default     = true
}

# Guacamole Configuration
variable "guacamole_admin_password" {
  description = "Guacamole admin password (REQUIRED - no default for security)"
  type        = string
  sensitive   = true
  # NO DEFAULT - must be explicitly set
  
  validation {
    condition     = length(var.guacamole_admin_password) >= 12
    error_message = "Guacamole password must be at least 12 characters long."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "SQL-Docker-Demos"
    ManagedBy   = "Terraform"
    Environment = "Demo"
  }
}

# Feature Flags
variable "deploy_windows_native_sql" {
  description = "Deploy SQL Server natively on Windows VM (not container)"
  type        = bool
  default     = true
}

variable "deploy_windows_container_sql" {
  description = "Deploy SQL Server as Windows container"
  type        = bool
  default     = false
}

variable "auto_shutdown_enabled" {
  description = "Enable automatic VM shutdown for cost savings"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time for automatic shutdown (24-hour format, e.g., 1900)"
  type        = string
  default     = "1900"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for automatic shutdown"
  type        = string
  default     = "Pacific Standard Time"
}

