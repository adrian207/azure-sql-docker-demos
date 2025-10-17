# Azure SQL Server Docker Demos - Network Configuration
# Author: Adrian Johnson <adrian207@gmail.com>
# GitHub: https://github.com/adrian207/azure-sql-docker-demos

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet for Linux VM
resource "azurerm_subnet" "linux" {
  name                 = "linux-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.linux_subnet_prefix]
}

# Subnet for Windows VM
resource "azurerm_subnet" "windows" {
  name                 = "windows-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.windows_subnet_prefix]
}

# Network Security Group for Linux VM
resource "azurerm_network_security_group" "linux" {
  name                = "${var.project_name}-linux-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  # Guacamole HTTP
  security_rule {
    name                       = "Guacamole-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  # Grafana
  security_rule {
    name                       = "Grafana"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  # Prometheus
  security_rule {
    name                       = "Prometheus"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  # SQL Server (for direct connections from Windows VM)
  security_rule {
    name                       = "SQL-Server"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433-1435"
    source_address_prefix      = var.windows_subnet_prefix
    destination_address_prefix = "*"
  }
}

# Network Security Group for Windows VM
resource "azurerm_network_security_group" "windows" {
  name                = "${var.project_name}-windows-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # RDP (from Linux VM only - accessed via Guacamole)
  security_rule {
    name                       = "RDP-from-Linux"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.linux_subnet_prefix
    destination_address_prefix = "*"
  }

  # SQL Server (from Linux VM)
  security_rule {
    name                       = "SQL-from-Linux"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.linux_subnet_prefix
    destination_address_prefix = "*"
  }

  # WinRM for configuration management
  security_rule {
    name                       = "WinRM"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985-5986"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }
}

# Associate NSG with Linux Subnet
resource "azurerm_subnet_network_security_group_association" "linux" {
  subnet_id                 = azurerm_subnet.linux.id
  network_security_group_id = azurerm_network_security_group.linux.id
}

# Associate NSG with Windows Subnet
resource "azurerm_subnet_network_security_group_association" "windows" {
  subnet_id                 = azurerm_subnet.windows.id
  network_security_group_id = azurerm_network_security_group.windows.id
}

# Public IP for Linux VM (for Guacamole/Grafana access)
resource "azurerm_public_ip" "linux" {
  name                = "${var.project_name}-linux-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface for Linux VM
resource "azurerm_network_interface" "linux" {
  name                = "${var.project_name}-linux-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "linux-ipconfig"
    subnet_id                     = azurerm_subnet.linux.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux.id
  }
}

# Network Interface for Windows VM
resource "azurerm_network_interface" "windows" {
  name                = "${var.project_name}-windows-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "windows-ipconfig"
    subnet_id                     = azurerm_subnet.windows.id
    private_ip_address_allocation = "Dynamic"
  }
}

