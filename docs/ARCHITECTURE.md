# Architecture Design Document

**Project:** Azure SQL Server Docker Demos  
**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0.0  
**Last Updated:** January 2025  
**Status:** Active  
**Classification:** Public

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Jan 2025 | Adrian Johnson | Initial architecture document |

### Document Purpose

This Architecture Design Document (ADD) provides a comprehensive technical specification of the Azure SQL Server Docker Demos infrastructure. It serves as the authoritative reference for system design, component interactions, and architectural decisions.

### Intended Audience

- **Infrastructure Engineers** - Deployment and maintenance
- **DevOps Teams** - CI/CD and automation
- **Security Teams** - Security review and compliance
- **Database Administrators** - SQL Server operations
- **Solutions Architects** - Architecture review and planning

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architectural Overview](#architectural-overview)
3. [System Components](#system-components)
4. [Network Architecture](#network-architecture)
5. [Security Architecture](#security-architecture)
6. [Data Architecture](#data-architecture)
7. [Deployment Architecture](#deployment-architecture)
8. [Scalability & Performance](#scalability--performance)
9. [High Availability & Disaster Recovery](#high-availability--disaster-recovery)
10. [Integration Points](#integration-points)
11. [Technology Stack](#technology-stack)
12. [Design Decisions & Rationale](#design-decisions--rationale)
13. [Constraints & Assumptions](#constraints--assumptions)
14. [Future Considerations](#future-considerations)

---

## 1. Executive Summary

### 1.1 System Overview

The Azure SQL Server Docker Demos platform is a production-ready, Infrastructure-as-Code (IaC) solution designed to demonstrate SQL Server high availability scenarios using containerized deployments on Microsoft Azure. The platform combines Windows Server, Linux, and SQL Server workloads in a secure, segmented, and cost-optimized architecture.

### 1.2 Key Architectural Characteristics

| Characteristic | Description | Status |
|----------------|-------------|--------|
| **Modularity** | Component-based design with clear separation of concerns | ✅ Implemented |
| **Scalability** | Horizontal and vertical scaling capabilities | ✅ Implemented |
| **Security** | Zero-trust network architecture with defense-in-depth | ✅ Implemented |
| **Observability** | Built-in monitoring and logging infrastructure | ⚠️ Partial |
| **Cost Optimization** | Auto-shutdown, right-sized resources, minimal waste | ✅ Implemented |
| **Maintainability** | Clean code, comprehensive documentation, version control | ✅ Implemented |

### 1.3 Deployment Models

```
┌──────────────────────────────────────────────────────────────┐
│                    Deployment Environments                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Development (dev)          Staging (staging)      Production (prod)
│  ├─ D4s_v3/D2s_v3          ├─ D8s_v3/D4s_v3       ├─ E8s_v3/D4s_v3
│  ├─ 256 GB storage         ├─ 512 GB storage      ├─ 1 TB storage
│  ├─ Auto-shutdown 6PM      ├─ Auto-shutdown 8PM   ├─ 24/7 operation
│  └─ ~$145/month            └─ ~$309/month         └─ ~$896/month
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Architectural Overview

### 2.1 Logical Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                               │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Apache Guacamole │  │ Grafana          │  │ Prometheus       │  │
│  │ (Web RDP/SSH)    │  │ (Dashboards)     │  │ (Metrics)        │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                               │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                 SQL Server Containers                         │  │
│  │  ┌───────────────┐ ┌───────────────┐ ┌────────────────────┐ │  │
│  │  │ Primary       │ │ Secondary     │ │ Witness (AG)       │ │  │
│  │  │ Port: 1433    │ │ Port: 1434    │ │ Port: 1435         │ │  │
│  │  └───────────────┘ └───────────────┘ └────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE LAYER                             │
│  ┌──────────────────┐          ┌────────────────────────────────┐  │
│  │ Rocky Linux VM   │          │ Windows Server 2022 VM         │  │
│  │ - Docker Runtime │          │ - SQL Server Management Studio │  │
│  │ - Container Host │          │ - Management Tools             │  │
│  └──────────────────┘          └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      NETWORK LAYER                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Azure Virtual Network (10.0.0.0/16)                          │  │
│  │  ├─ Linux Subnet (10.0.1.0/24)                              │  │
│  │  ├─ Windows Subnet (10.0.2.0/24)                            │  │
│  │  ├─ Network Security Groups                                 │  │
│  │  └─ Public IP (Linux only)                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      STORAGE LAYER                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │ OS Disks         │  │ Data Disks       │  │ Container       │  │
│  │ (Premium SSD)    │  │ (Premium SSD)    │  │ Volumes         │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Physical Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                      Azure Region (West US 2)                       │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                   Resource Group                            │   │
│  │  [sql-docker-demo-{env}-rg-{random}]                       │   │
│  ├────────────────────────────────────────────────────────────┤   │
│  │                                                             │   │
│  │  Virtual Network                                            │   │
│  │  ┌──────────────────────────────────────────────────────┐  │   │
│  │  │ Address Space: 10.0.0.0/16                           │  │   │
│  │  │                                                       │  │   │
│  │  │  ┌────────────────────────────────────────────────┐  │  │   │
│  │  │  │ Linux Subnet (10.0.1.0/24)                    │  │  │   │
│  │  │  │  ┌──────────────────────────────────────────┐ │  │  │   │
│  │  │  │  │ Rocky Linux VM (Standard_D8s_v3)        │ │  │  │   │
│  │  │  │  │ - Public IP: 20.x.x.x                   │ │  │  │   │
│  │  │  │  │ - Private IP: 10.0.1.4                  │ │  │  │   │
│  │  │  │  │ - OS Disk: 512 GB Premium SSD          │ │  │  │   │
│  │  │  │  │ - Data Disk: 512 GB Premium SSD        │ │  │  │   │
│  │  │  │  │                                          │ │  │  │   │
│  │  │  │  │ Docker Containers:                      │ │  │  │   │
│  │  │  │  │  • sql-primary:1433                     │ │  │  │   │
│  │  │  │  │  • sql-secondary:1434                   │ │  │  │   │
│  │  │  │  │  • sql-witness:1435                     │ │  │  │   │
│  │  │  │  │  • guacamole:8080                       │ │  │  │   │
│  │  │  │  │  • grafana:3000                         │ │  │  │   │
│  │  │  │  │  • prometheus:9090                      │ │  │  │   │
│  │  │  │  └──────────────────────────────────────────┘ │  │  │   │
│  │  │  └────────────────────────────────────────────────┘  │  │   │
│  │  │                                                       │  │   │
│  │  │  ┌────────────────────────────────────────────────┐  │  │   │
│  │  │  │ Windows Subnet (10.0.2.0/24)                  │  │  │   │
│  │  │  │  ┌──────────────────────────────────────────┐ │  │  │   │
│  │  │  │  │ Windows Server 2022 (Standard_D4s_v3)   │ │  │  │   │
│  │  │  │  │ - NO Public IP (Guacamole only)         │ │  │  │   │
│  │  │  │  │ - Private IP: 10.0.2.4                  │ │  │  │   │
│  │  │  │  │ - OS Disk: 256 GB Premium SSD          │ │  │  │   │
│  │  │  │  │ - Data Disk: 512 GB Premium SSD        │ │  │  │   │
│  │  │  │  │                                          │ │  │  │   │
│  │  │  │  │ Installed Software:                     │ │  │  │   │
│  │  │  │  │  • SQL Server Management Studio         │ │  │  │   │
│  │  │  │  │  • Google Chrome                        │ │  │  │   │
│  │  │  │  │  • Notepad++, 7-Zip                     │ │  │  │   │
│  │  │  │  │  • (Optional) SQL Server 2022           │ │  │  │   │
│  │  │  │  └──────────────────────────────────────────┘ │  │  │   │
│  │  │  └────────────────────────────────────────────────┘  │  │   │
│  │  └──────────────────────────────────────────────────────┘  │   │
│  │                                                             │   │
│  │  Network Security Groups                                   │   │
│  │  ├─ linux-nsg                                              │   │
│  │  │   Rules: SSH(22), HTTP(8080), Grafana(3000),          │   │
│  │  │          Prometheus(9090), SQL(1433-1435)             │   │
│  │  │                                                         │   │
│  │  └─ windows-nsg                                            │   │
│  │      Rules: RDP(3389) from Linux subnet only,            │   │
│  │             SQL(1433) from Linux subnet only              │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. System Components

### 3.1 Compute Resources

#### 3.1.1 Linux Virtual Machine (Rocky Linux 9)

**Purpose:** Container host for SQL Server instances and monitoring infrastructure

**Specifications:**
```yaml
Name: sql-docker-demo-linux-vm
Operating System: Rocky Linux 9.4
VM Size:
  Development: Standard_D4s_v3 (4 vCPU, 16 GB RAM)
  Staging: Standard_D8s_v3 (8 vCPU, 32 GB RAM)
  Production: Standard_E8s_v3 (8 vCPU, 64 GB RAM - memory optimized)

Storage:
  OS Disk:
    Type: Premium SSD (P10 - P20)
    Size: 256-512 GB
    Caching: ReadWrite
  
  Data Disk:
    Type: Premium SSD (P15 - P30)
    Size: 256-1024 GB
    Caching: ReadWrite
    Mount: /mnt/data
    Purpose: Docker volumes

Networking:
  Public IP: Yes (Static, Standard SKU)
  Private IP: Dynamic (10.0.1.0/24 range)
  Accelerated Networking: Recommended (not yet enabled)
  
Authentication:
  Method: SSH public key (password auth disabled)
  User: sqladmin

Provisioning:
  Method: cloud-init
  Packages: docker, docker-compose, monitoring tools
  Auto-start: Docker containers via compose
```

**Installed Software:**
- Docker CE (latest)
- Docker Compose v2
- Git, curl, wget, net-tools
- System monitoring tools (htop, iostat)

#### 3.1.2 Windows Virtual Machine (Windows Server 2022)

**Purpose:** SQL Server management and administrative access

**Specifications:**
```yaml
Name: sql-docker-demo-windows-vm
Operating System: Windows Server 2022 Datacenter Azure Edition
VM Size:
  Development: Standard_D2s_v3 (2 vCPU, 8 GB RAM)
  Staging/Production: Standard_D4s_v3 (4 vCPU, 16 GB RAM)

Storage:
  OS Disk:
    Type: Premium SSD (P10)
    Size: 128-256 GB
    Caching: ReadWrite
  
  Data Disk (if native SQL deployed):
    Type: Premium SSD (P20 - P30)
    Size: 512-1024 GB
    Caching: ReadOnly (for SQL data)
    Drive Letter: F:\
    Purpose: SQL Server data and logs

Networking:
  Public IP: NO (secure by design)
  Private IP: Dynamic (10.0.2.0/24 range)
  Accelerated Networking: Recommended
  
Authentication:
  Method: Username/Password
  User: sqladmin
  RDP Access: Via Guacamole only

Provisioning:
  Method: Custom Script Extension (PowerShell)
  Auto-install: SSMS, Chrome, Notepad++, 7-Zip
  Optional: SQL Server 2022 Developer Edition
```

**Installed Software:**
- SQL Server Management Studio (SSMS) 19
- Google Chrome
- Notepad++
- 7-Zip
- (Optional) SQL Server 2022 Developer Edition

### 3.2 Container Infrastructure

#### 3.2.1 SQL Server Containers

**Base Image:** `mcr.microsoft.com/mssql/server:2022-latest`

```yaml
sql-primary:
  container_name: sql-primary
  image: mcr.microsoft.com/mssql/server:2022-latest
  ports:
    - "1433:1433"
  environment:
    ACCEPT_EULA: "Y"
    SA_PASSWORD: ${sql_sa_password}
    MSSQL_PID: "Developer"
    MSSQL_AGENT_ENABLED: "true"
  volumes:
    - sql-primary-data:/var/opt/mssql
    - /opt/sql-docker/backups:/var/opt/mssql/backup
  networks:
    - sql-network
  restart: unless-stopped
  resources:
    limits:
      memory: 8G
      cpus: '2'
  healthcheck:
    test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${sql_sa_password} -Q "SELECT 1"
    interval: 30s
    timeout: 10s
    retries: 5

sql-secondary:
  # Similar configuration on port 1434

sql-witness:
  # Similar configuration on port 1435 (for Always On AG)
```

#### 3.2.2 Monitoring Stack

**Prometheus:**
```yaml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--storage.tsdb.retention.time=30d'
```

**Grafana:**
```yaml
grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
  environment:
    GF_SECURITY_ADMIN_PASSWORD: ${grafana_admin_password}
    GF_INSTALL_PLUGINS: grafana-clock-panel
  volumes:
    - grafana-data:/var/lib/grafana
```

#### 3.2.3 Remote Access (Guacamole)

```yaml
guacamole-db:
  image: postgres:15
  environment:
    POSTGRES_DB: guacamole_db
    POSTGRES_USER: guacamole_user
    POSTGRES_PASSWORD: ${guacamole_db_password}

guacd:
  image: guacamole/guacd:latest

guacamole:
  image: guacamole/guacamole:latest
  ports:
    - "8080:8080"
  environment:
    GUACD_HOSTNAME: guacd
    POSTGRES_HOSTNAME: guacamole-db
    POSTGRES_DATABASE: guacamole_db
```

---

## 4. Network Architecture

### 4.1 Network Topology

```
Internet
    │
    ├─ Public IP (20.x.x.x) ─────────────┐
    │                                     │
    │                            ┌────────▼────────┐
    │                            │  Linux Subnet   │
    │                            │  10.0.1.0/24    │
    │                            │                 │
    │                            │  Linux VM       │
    │                            │  10.0.1.4       │
    │                            └────────┬────────┘
    │                                     │
    │                            ┌────────▼────────┐
    │                            │ Windows Subnet  │
    │                            │ 10.0.2.0/24     │
    │                            │                 │
    │                            │ Windows VM      │
    │                            │ 10.0.2.4        │
    │                            │ (No Public IP)  │
    │                            └─────────────────┘
    │
    └─ Azure Services (PaaS)
```

### 4.2 Network Security Groups

**Linux NSG Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Port | Action |
|----------|------|-----------|----------|--------|-------------|------|--------|
| 1001 | SSH | Inbound | TCP | ${allowed_ip_ranges} | * | 22 | Allow |
| 1002 | Guacamole-HTTP | Inbound | TCP | ${allowed_ip_ranges} | * | 8080 | Allow |
| 1003 | Grafana | Inbound | TCP | ${allowed_ip_ranges} | * | 3000 | Allow |
| 1004 | Prometheus | Inbound | TCP | ${allowed_ip_ranges} | * | 9090 | Allow |
| 1005 | SQL-Server | Inbound | TCP | 10.0.2.0/24 | * | 1433-1435 | Allow |
| 65000 | DenyAllInbound | Inbound | * | * | * | * | Deny |

**Windows NSG Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Port | Action |
|----------|------|-----------|----------|--------|-------------|------|--------|
| 1001 | RDP-from-Linux | Inbound | TCP | 10.0.1.0/24 | * | 3389 | Allow |
| 1002 | SQL-from-Linux | Inbound | TCP | 10.0.1.0/24 | * | 1433 | Allow |
| 65000 | DenyAllInbound | Inbound | * | * | * | * | Deny |

### 4.3 DNS and Name Resolution

```
Internal DNS:
- Managed by Azure VNet DNS
- VM names resolve to private IPs within VNet
- External DNS queries forwarded to Azure DNS

Resolution Examples:
- sql-docker-demo-linux-vm  → 10.0.1.4
- sql-docker-demo-windows-vm → 10.0.2.4
- sql-primary.container → 10.0.1.4:1433
```

---

## 5. Security Architecture

### 5.1 Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 7: Application Security                               │
│ - SQL authentication & authorization                        │
│ - Guacamole role-based access                              │
│ - Grafana authentication                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 6: Container Security                                 │
│ - Image scanning                                            │
│ - Resource limits                                           │
│ - No privileged containers                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 5: Host Security                                      │
│ - SSH key authentication (Linux)                            │
│ - OS patching and updates                                   │
│ - Firewall rules                                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Network Security                                   │
│ - Network Security Groups                                   │
│ - Subnet isolation                                          │
│ - No public IPs on workloads                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Identity & Access                                  │
│ - Azure RBAC                                                │
│ - Managed identities (future)                              │
│ - Key Vault integration (future)                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Data Security                                      │
│ - Encryption at rest (Azure Storage)                       │
│ - TLS in transit (future enhancement)                      │
│ - Backup encryption                                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Physical Security                                  │
│ - Azure datacenter security                                 │
│ - Hardware security modules                                 │
│ - Geographic redundancy                                     │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Authentication & Authorization Matrix

| Component | Authentication Method | Authorization Model | MFA Support |
|-----------|----------------------|---------------------|-------------|
| Azure Portal | Azure AD | RBAC | Yes |
| Linux VM (SSH) | SSH Public Key | OS-level (sudo) | N/A |
| Windows VM (RDP) | Username/Password | Local Admin | Via Guacamole |
| Guacamole | Username/Password | Guacamole DB | Optional |
| SQL Server | SQL Authentication | SQL Server Roles | No |
| Grafana | Username/Password | Grafana Roles | Optional |
| Prometheus | None (internal) | Network-level | N/A |

### 5.3 Secrets Management

**Current State:**
- Passwords stored in `terraform.tfvars` (gitignored)
- Variables marked `sensitive = true` in Terraform
- Cloud-init receives secrets as template variables

**Recommended Enhancement:**
```hcl
# Use Azure Key Vault
data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-sa-password"
  key_vault_id = var.key_vault_id
}

# Reference in resources
environment = {
  SA_PASSWORD = data.azurerm_key_vault_secret.sql_password.value
}
```

---

## 6. Data Architecture

### 6.1 Data Flow Diagram

```
┌───────────────────────────────────────────────────────────────────┐
│                        Data Flow                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│  User Input (SSMS)                                                │
│        │                                                           │
│        ▼                                                           │
│  ┌────────────────┐                                              │
│  │ Windows VM     │                                              │
│  │ (Management)   │                                              │
│  └────────┬───────┘                                              │
│           │ SQL Protocol (1433-1435)                             │
│           ▼                                                       │
│  ┌────────────────┐      ┌────────────────┐                     │
│  │ SQL Primary    │─────▶│ SQL Secondary  │                     │
│  │ Container      │      │ Container      │                     │
│  │ (1433)         │      │ (1434)         │                     │
│  └────────┬───────┘      └────────┬───────┘                     │
│           │                       │                              │
│           │ Replication           │ Replication                 │
│           ▼                       ▼                              │
│  ┌────────────────┐      ┌────────────────┐                     │
│  │ Data Volume    │      │ Data Volume    │                     │
│  │ /var/opt/mssql │      │ /var/opt/mssql │                     │
│  └────────┬───────┘      └────────┬───────┘                     │
│           │                       │                              │
│           └───────┬───────────────┘                              │
│                   │                                              │
│                   ▼                                              │
│          ┌────────────────┐                                      │
│          │ Data Disk      │                                      │
│          │ /mnt/data      │                                      │
│          │ (Premium SSD)  │                                      │
│          └────────────────┘                                      │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘
```

### 6.2 Storage Architecture

**Volume Types:**

| Volume Type | Purpose | Redundancy | Backup | Retention |
|-------------|---------|------------|--------|-----------|
| OS Disks | Operating system files | LRS | Azure Backup | 30 days |
| Data Disks | SQL data files | LRS/ZRS | Azure Backup | 30-90 days |
| Container Volumes | SQL data persistence | LRS | Docker volumes | Manual |
| Backup Storage | Database backups | GRS | N/A | 30 days |

**Performance Tiers:**

```
Development:
├─ OS Disks: Premium SSD P10 (120 IOPS, 25 MB/s)
└─ Data Disks: Premium SSD P15 (1100 IOPS, 125 MB/s)

Staging:
├─ OS Disks: Premium SSD P15 (1100 IOPS, 125 MB/s)
└─ Data Disks: Premium SSD P20 (2300 IOPS, 150 MB/s)

Production:
├─ OS Disks: Premium SSD P20 (2300 IOPS, 150 MB/s)
└─ Data Disks: Premium SSD P30 (5000 IOPS, 200 MB/s)
```

---

## 7. Deployment Architecture

### 7.1 Infrastructure as Code Stack

```
┌─────────────────────────────────────────────────────────────┐
│                   IaC Technology Stack                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Version Control                                            │
│  ├─ Git (GitHub)                                            │
│  └─ Branch Strategy: main (single branch)                  │
│                                                              │
│  Infrastructure Provisioning                                │
│  ├─ Terraform >= 1.5.0                                     │
│  ├─ Azure RM Provider ~> 3.80                              │
│  └─ Workspaces: dev, staging, prod                         │
│                                                              │
│  Configuration Management                                   │
│  ├─ Cloud-init (Linux)                                     │
│  ├─ Custom Script Extension (Windows)                      │
│  └─ Docker Compose v2                                       │
│                                                              │
│  Container Orchestration                                    │
│  ├─ Docker Compose (current)                               │
│  └─ Kubernetes/AKS (future)                                │
│                                                              │
│  State Management                                           │
│  ├─ Local state (current)                                  │
│  └─ Azure Storage (recommended)                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Deployment Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│                    Deployment Process                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. PREPARE                                                      │
│     ├─ Clone repository                                          │
│     ├─ Configure environment variables                           │
│     └─ Authenticate to Azure                                     │
│                                                                   │
│  2. PLAN                                                         │
│     ├─ terraform init                                            │
│     ├─ terraform workspace select {env}                          │
│     ├─ terraform plan -var-file=environments/{env}.tfvars        │
│     └─ Review changes                                            │
│                                                                   │
│  3. PROVISION                                                    │
│     ├─ terraform apply                                           │
│     ├─ Create resource group                                     │
│     ├─ Deploy network infrastructure                             │
│     ├─ Deploy virtual machines                                   │
│     └─ Configure auto-shutdown                                   │
│                                                                   │
│  4. CONFIGURE                                                    │
│     ├─ Cloud-init executes (Linux)                              │
│     ├─ Custom script extension (Windows)                        │
│     ├─ Docker containers start                                  │
│     └─ Services initialize                                       │
│                                                                   │
│  5. VALIDATE                                                     │
│     ├─ Check VM status                                          │
│     ├─ Verify container health                                  │
│     ├─ Test connectivity                                        │
│     └─ Access services                                          │
│                                                                   │
│  6. OPERATE                                                      │
│     ├─ Monitor resources                                        │
│     ├─ Manage backups                                           │
│     └─ Handle incidents                                         │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

Estimated Deployment Time: 10-15 minutes
```

---

## 8. Scalability & Performance

### 8.1 Vertical Scaling (Scale Up)

**Compute Scaling:**

```
Current Development → Staging:
├─ Linux: D4s_v3 (4 CPU, 16 GB) → D8s_v3 (8 CPU, 32 GB)
├─ Change: terraform.tfvars → linux_vm_size = "Standard_D8s_v3"
├─ Impact: Requires VM restart (~5 minutes)
└─ Cost: +$70/month

Staging → Production:
├─ Linux: D8s_v3 (8 CPU, 32 GB) → E8s_v3 (8 CPU, 64 GB)
├─ Benefit: 2x memory for SQL Server performance
└─ Cost: +$100/month
```

**Storage Scaling:**

```
Increase Disk Size:
├─ Method: Azure Portal or Terraform
├─ Downtime: Yes (disk detach/reattach)
├─ Data Loss: No (preserves data)
└─ Steps:
    1. Stop VM
    2. Increase disk size
    3. Start VM
    4. Extend filesystem
```

### 8.2 Horizontal Scaling (Scale Out)

**Container Scaling:**

```yaml
# Scale SQL Server containers
docker-compose up -d --scale sql-secondary=3

# Limitations:
# - Port conflicts (need unique ports)
# - Shared host resources
# - Manual configuration required
```

**VM Scaling:**

```hcl
# Add additional Linux hosts
module "linux_vm" {
  count = 2  # Deploy 2 hosts
  # ...
}

# Use case:
# - Separate hosts for different SQL demos
# - Load distribution
# - High availability
```

### 8.3 Performance Optimization

**Database Performance:**

```sql
-- Optimize SQL Server settings
EXEC sp_configure 'max server memory (MB)', 24576; -- Leave 8GB for OS
EXEC sp_configure 'min server memory (MB)', 16384;
EXEC sp_configure 'cost threshold for parallelism', 50;
EXEC sp_configure 'max degree of parallelism', 4;
RECONFIGURE;
```

**Container Resource Limits:**

```yaml
services:
  sql-primary:
    deploy:
      resources:
        limits:
          cpus: '4'       # Max 4 CPUs
          memory: 16G     # Max 16 GB RAM
        reservations:
          cpus: '2'       # Guaranteed 2 CPUs
          memory: 8G      # Guaranteed 8 GB RAM
```

**Network Performance:**

```hcl
# Enable accelerated networking
resource "azurerm_network_interface" "linux" {
  enable_accelerated_networking = true  # Up to 30 Gbps
}
```

---

## 9. High Availability & Disaster Recovery

### 9.1 SQL Server HA Scenarios

**Log Shipping:**
```
Primary (sql-primary:1433)
    │
    ├─ Transaction Log Backup (every 15 min)
    │
    ▼
Secondary (sql-secondary:1434)
    │
    └─ Log Restore (standby mode)

RPO: 15 minutes
RTO: 5-10 minutes (manual failover)
Use Case: Warm standby, reporting offload
```

**Transactional Replication:**
```
Publisher (sql-primary:1433)
    │
    ├─ Push Changes (continuous)
    │
    ▼
Subscriber (sql-secondary:1434)

RPO: <5 seconds
RTO: N/A (read-only secondary)
Use Case: Data distribution, reporting
```

**Always On Availability Groups:**
```
Primary Replica (sql-primary:1433)
    │
    ├─ Synchronous Commit
    │
    ▼
Secondary Replica (sql-secondary:1434)
    │
    └─ Automatic Failover
        (with Witness: sql-witness:1435)

RPO: 0 (synchronous) or <5s (asynchronous)
RTO: <30 seconds (automatic failover)
Use Case: Mission-critical databases
```

### 9.2 Infrastructure HA

**Current State:**
- ❌ Single VM = Single point of failure
- ❌ No availability zones
- ❌ No VM Scale Sets
- ❌ No load balancing

**Recommended Enhancements:**

```hcl
# Deploy across availability zones
resource "azurerm_linux_virtual_machine" "linux" {
  zones = ["1"]  # Or 2, 3
}

# Add Azure Load Balancer
resource "azurerm_lb" "sql" {
  frontend_ip_configuration {
    name                 = "sql-frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Add VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "linux" {
  instances = 2
  zones     = ["1", "2"]
}
```

### 9.3 Disaster Recovery Plan

**Backup Strategy:**

| Component | Backup Method | Frequency | Retention |
|-----------|--------------|-----------|-----------|
| VMs | Azure Backup | Daily | 30 days |
| SQL Databases | SQL Server Backup | Hourly | 7 days |
| Container Volumes | Docker volume backup | Daily | 7 days |
| Infrastructure Code | Git | Continuous | Infinite |
| Configuration | Git | Continuous | Infinite |

**Recovery Procedures:**

```
Scenario 1: Single VM Failure
├─ Detection: 5 minutes (monitoring alerts)
├─ Action: Redeploy from Terraform
├─ RTO: 15 minutes
└─ RPO: Last backup (1 hour)

Scenario 2: Region Failure
├─ Detection: 15 minutes
├─ Action: Deploy to secondary region
├─ RTO: 30 minutes
└─ RPO: Last geo-replicated backup

Scenario 3: Data Corruption
├─ Detection: Variable (user report)
├─ Action: Restore from backup
├─ RTO: 1-2 hours
└─ RPO: Last backup point
```

---

## 10. Integration Points

### 10.1 External Integrations

**Azure Services:**
```
Current:
├─ Azure Resource Manager (ARM)
├─ Azure Virtual Network
├─ Azure Managed Disks
└─ Azure DevTest Labs (auto-shutdown)

Recommended:
├─ Azure Key Vault (secrets management)
├─ Azure Monitor (metrics and logs)
├─ Azure Backup (VM backups)
├─ Azure Security Center (threat detection)
└─ Azure Policy (compliance)
```

**Third-Party Services:**
```
Monitoring:
├─ Prometheus (metrics collection)
├─ Grafana (visualization)
└─ (Future) Datadog, New Relic

Container Registry:
└─ (Future) Azure Container Registry

CI/CD:
└─ (Future) GitHub Actions, Azure DevOps
```

### 10.2 API Endpoints

**Exposed Services:**

| Service | Protocol | Port | Authentication | Purpose |
|---------|----------|------|----------------|---------|
| Guacamole | HTTP | 8080 | Username/Password | Remote desktop gateway |
| Grafana | HTTP | 3000 | Username/Password | Metrics visualization |
| Prometheus | HTTP | 9090 | None | Metrics API |
| SQL Server | TCP | 1433-1435 | SQL Authentication | Database access |
| SSH | TCP | 22 | Public Key | Linux management |

---

## 11. Technology Stack

### 11.1 Complete Technology Inventory

**Infrastructure:**
```
Cloud Platform: Microsoft Azure
Region: West US 2 (configurable)
Compute: Azure Virtual Machines (Dsv3, Esv3 series)
Storage: Azure Managed Disks (Premium SSD)
Networking: Azure Virtual Network, NSGs
```

**Operating Systems:**
```
Linux: Rocky Linux 9.4
Windows: Windows Server 2022 Datacenter Azure Edition
Container Runtime: Docker CE 24.x
```

**Databases:**
```
Primary: SQL Server 2022 Developer Edition (Linux containers)
Supporting: PostgreSQL 15 (Guacamole metadata)
```

**IaC & Automation:**
```
Provisioning: Terraform >= 1.5.0
Configuration: Cloud-init, PowerShell DSC
Orchestration: Docker Compose v2
Version Control: Git, GitHub
```

**Monitoring & Observability:**
```
Metrics: Prometheus 2.x
Visualization: Grafana 10.x
Logging: (Future) ELK Stack or Azure Monitor
APM: (Future) Application Insights
```

**Security:**
```
Authentication: SSH Keys, SQL Authentication
Secrets: Terraform variables (current), Key Vault (future)
Network Security: Azure NSGs
```

**Remote Access:**
```
Gateway: Apache Guacamole 1.5.x
Protocol Support: RDP, SSH, VNC
Database: PostgreSQL
```

### 11.2 Version Matrix

| Component | Minimum Version | Recommended | Latest Tested |
|-----------|----------------|-------------|---------------|
| Terraform | 1.5.0 | 1.6.x | 1.6.4 |
| Azure CLI | 2.50.0 | 2.55.x | 2.55.1 |
| Docker | 20.10 | 24.x | 24.0.7 |
| Docker Compose | 2.0 | 2.23.x | 2.23.0 |
| Rocky Linux | 9.0 | 9.4 | 9.4 |
| Windows Server | 2022 | 2022 | 2022 |
| SQL Server | 2022 | 2022 | 2022-latest |
| Guacamole | 1.4.0 | 1.5.x | 1.5.4 |
| Prometheus | 2.40 | 2.48.x | 2.48.1 |
| Grafana | 9.0 | 10.2.x | 10.2.3 |

---

## 12. Design Decisions & Rationale

### 12.1 Key Architectural Decisions

| Decision | Rationale | Trade-offs | Status |
|----------|-----------|------------|--------|
| **Docker Compose vs Kubernetes** | Simpler for demos, lower overhead, easier to understand | Less scalability, no auto-healing, manual management | Implemented |
| **Guacamole vs Azure Bastion** | Cost savings ($140/month), full RDP/SSH features, self-hosted | Requires maintenance, single point of failure, HTTP only | Implemented |
| **Rocky Linux vs Ubuntu** | RHEL-compatible, enterprise-grade, free, long support | Less familiar to some, smaller community than Ubuntu | Implemented |
| **Single Linux host** | Cost optimization, simplicity, demo-appropriate | Single point of failure, resource contention, scalability limits | Implemented |
| **No public IP on Windows** | Security best practice, reduces attack surface, compliance | Requires Guacamole for access, adds complexity | Implemented |
| **Premium SSD** | Performance for SQL Server, predictable IOPS, low latency | Higher cost than Standard SSD, may be overkill for dev | Implemented |
| **Environment-based configs** | No code drift, easy promotion, single source of truth | Requires discipline, workspace management | Implemented |
| **Local state** | Simplicity, no additional infrastructure, quick start | No team collaboration, no locking, manual backups | Implemented |

### 12.2 Design Patterns Applied

**Infrastructure:**
- ✅ Infrastructure as Code (IaC)
- ✅ Immutable Infrastructure
- ✅ Configuration as Code
- ✅ Environment Parity (dev/staging/prod)

**Security:**
- ✅ Defense in Depth
- ✅ Least Privilege
- ✅ Network Segmentation
- ✅ Zero Trust (partial)

**Operations:**
- ✅ Everything as Code
- ✅ Self-Service Infrastructure
- ✅ Automated Provisioning
- ⚠️ GitOps (future)

**Cost:**
- ✅ Right-Sizing
- ✅ Auto-Shutdown
- ✅ Resource Tagging
- ⚠️ Reserved Instances (manual)

---

## 13. Constraints & Assumptions

### 13.1 Constraints

**Technical:**
- Azure subscription required
- Terraform >= 1.5.0 required
- Linux/Windows platform support
- Single-region deployment (current)
- No cross-region replication

**Operational:**
- Manual deployment process
- No automated testing
- No CI/CD pipeline
- Limited monitoring/alerting
- Manual backup management

**Security:**
- Demo/development use case
- Not production-hardened by default
- Requires manual Key Vault integration
- No MFA enforcement
- No audit logging enabled

**Cost:**
- Pay-as-you-go pricing
- No cost controls enforced
- Manual resource management
- Auto-shutdown for cost savings

### 13.2 Assumptions

**Environment:**
- User has Azure subscription with appropriate permissions
- User has basic Azure knowledge
- User has Terraform experience
- User has SQL Server knowledge
- Internet connectivity available

**Usage:**
- Demo and learning purposes
- Non-production workloads
- Short-lived environments
- Single user or small team
- Development/testing focus

**Resources:**
- Sufficient Azure quota available
- Default service limits acceptable
- Standard Azure regions used
- No special compliance requirements
- No data residency constraints

---

## 14. Future Considerations

### 14.1 Planned Enhancements

**Phase 1: Security Hardening (Q1 2025)**
- [ ] Azure Key Vault integration
- [ ] TLS/HTTPS for all services
- [ ] Private endpoints
- [ ] Azure Security Center
- [ ] NSG flow logs

**Phase 2: Operational Excellence (Q2 2025)**
- [ ] Azure Backup integration
- [ ] Automated testing
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Log aggregation (Azure Monitor)
- [ ] Automated alerting

**Phase 3: Scalability & HA (Q3 2025)**
- [ ] Kubernetes/AKS migration
- [ ] Multi-region deployment
- [ ] Load balancing
- [ ] Auto-scaling
- [ ] Disaster recovery automation

**Phase 4: Advanced Features (Q4 2025)**
- [ ] Managed identities
- [ ] Azure Policy enforcement
- [ ] Cost management automation
- [ ] Advanced monitoring dashboards
- [ ] Performance optimization

### 14.2 Migration Paths

**To Kubernetes:**
```
Current: Docker Compose on single host
    ↓
Target: Azure Kubernetes Service (AKS)

Benefits:
- Auto-healing
- Horizontal scaling
- Rolling updates
- Better resource management

Effort: 2-3 weeks
Cost Impact: +$200-300/month
```

**To Multi-Region:**
```
Current: Single region (West US 2)
    ↓
Target: Primary + DR region (East US)

Benefits:
- Geographic redundancy
- Disaster recovery
- Lower latency for distributed users

Effort: 1-2 weeks
Cost Impact: +100% (duplicate resources)
```

### 14.3 Technology Evolution

**Container Orchestration:**
```
Docker Compose → Kubernetes/AKS → Managed Container Platforms

Timeframe: 6-12 months
Driver: Scale and automation requirements
```

**Secrets Management:**
```
Terraform Variables → Azure Key Vault → HashiCorp Vault

Timeframe: 3-6 months
Driver: Security and compliance
```

**Monitoring:**
```
Prometheus/Grafana → Azure Monitor → Full observability stack

Timeframe: 6-9 months
Driver: Enterprise requirements
```

---

## Appendices

### A. Glossary

| Term | Definition |
|------|------------|
| **ADD** | Architecture Design Document |
| **AKS** | Azure Kubernetes Service |
| **ARM** | Azure Resource Manager |
| **DR** | Disaster Recovery |
| **HA** | High Availability |
| **IaC** | Infrastructure as Code |
| **NSG** | Network Security Group |
| **RBAC** | Role-Based Access Control |
| **RTO** | Recovery Time Objective |
| **RPO** | Recovery Point Objective |
| **SLA** | Service Level Agreement |
| **VM** | Virtual Machine |
| **VNet** | Virtual Network |

### B. References

**Documentation:**
- Azure Virtual Machines: https://docs.microsoft.com/azure/virtual-machines/
- Terraform Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm
- SQL Server on Linux: https://docs.microsoft.com/sql/linux/
- Docker Documentation: https://docs.docker.com/
- Apache Guacamole: https://guacamole.apache.org/doc/gug/

**Project Resources:**
- GitHub Repository: https://github.com/adrian207/azure-sql-docker-demos
- Main README: ../README.md
- Quick Start Guide: ../QUICKSTART.md
- Environment Guide: ../ENVIRONMENTS.md

### C. Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0.0 | Jan 2025 | Adrian Johnson | Initial architecture document |

---

## Document Review & Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Author** | Adrian Johnson | | Jan 2025 |
| **Reviewer** | | | |
| **Approver** | | | |

---

**Document Classification:** Public  
**Document Owner:** Adrian Johnson <adrian207@gmail.com>  
**Last Review Date:** January 2025  
**Next Review Date:** July 2025

---

*This document is maintained in the project repository and version-controlled via Git.*

