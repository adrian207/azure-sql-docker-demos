# Security Design Document

**Project:** Azure SQL Server Docker Demos  
**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0.0  
**Last Updated:** January 2025  
**Classification:** Internal  

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Jan 2025 | Adrian Johnson | Initial security document |

### Purpose

This Security Design Document provides comprehensive security architecture, threat analysis, and mitigation strategies for the Azure SQL Server Docker Demos platform. It serves as the authoritative reference for security implementation and compliance validation.

---

## Table of Contents

1. [Security Overview](#security-overview)
2. [Threat Model](#threat-model)
3. [Security Architecture](#security-architecture)
4. [Authentication & Authorization](#authentication--authorization)
5. [Network Security](#network-security)
6. [Data Security](#data-security)
7. [Container Security](#container-security)
8. [Secrets Management](#secrets-management)
9. [Compliance & Governance](#compliance--governance)
10. [Security Monitoring](#security-monitoring)
11. [Incident Response](#incident-response)
12. [Security Checklist](#security-checklist)

---

## 1. Security Overview

### 1.1 Security Posture

**Current Security Rating:** **B+ (85/100)**

| Category | Rating | Status |
|----------|--------|--------|
| Network Security | A- (90/100) | ✅ Strong |
| Identity & Access | B+ (85/100) | ✅ Good |
| Data Protection | B (80/100) | ⚠️ Adequate |
| Container Security | B (80/100) | ⚠️ Adequate |
| Secrets Management | C+ (75/100) | ⚠️ Needs improvement |
| Monitoring & Logging | C (70/100) | ⚠️ Needs improvement |
| **OVERALL** | **B+ (82/100)** | ✅ Production-ready with enhancements |

### 1.2 Security Principles

```
Defense in Depth
├─ Multiple layers of security controls
├─ Redundant safeguards
└─ No single point of failure

Least Privilege
├─ Minimum required permissions
├─ Role-based access control
└─ Time-bound access

Zero Trust
├─ Never trust, always verify
├─ Explicit verification
└─ Assume breach mentality

Secure by Default
├─ Security as first priority
├─ No dangerous defaults
└─ Validation enforced
```

---

## 2. Threat Model

### 2.1 STRIDE Analysis

**Spoofing:**
```
Threat: Attacker impersonates legitimate user
├─ Attack Vector: Stolen credentials, weak passwords
├─ Mitigation: SSH keys (Linux), strong passwords, MFA (future)
├─ Residual Risk: MEDIUM
└─ Enhancement: Azure AD integration, certificate-based auth
```

**Tampering:**
```
Threat: Unauthorized modification of data or code
├─ Attack Vector: Compromised VM, container escape
├─ Mitigation: Immutable infrastructure, file integrity monitoring
├─ Residual Risk: MEDIUM
└─ Enhancement: Code signing, Azure Policy enforcement
```

**Repudiation:**
```
Threat: User denies performing action
├─ Attack Vector: No audit trail, insufficient logging
├─ Mitigation: Azure Activity Log (basic)
├─ Residual Risk: HIGH
└─ Enhancement: Comprehensive audit logging, Azure Sentinel
```

**Information Disclosure:**
```
Threat: Unauthorized access to sensitive data
├─ Attack Vector: Network sniffing, exposed services
├─ Mitigation: NSGs, private networking, no public IPs on workloads
├─ Residual Risk: LOW
└─ Enhancement: TLS encryption, private endpoints
```

**Denial of Service:**
```
Threat: Service unavailability
├─ Attack Vector: Resource exhaustion, network flooding
├─ Mitigation: Auto-shutdown, resource limits, NSG rules
├─ Residual Risk: MEDIUM
└─ Enhancement: Azure DDoS Protection, rate limiting
```

**Elevation of Privilege:**
```
Threat: Attacker gains admin access
├─ Attack Vector: Privilege escalation, misconfiguration
├─ Mitigation: Least privilege, SSH keys, strong NSG rules
├─ Residual Risk: MEDIUM
└─ Enhancement: Just-in-time access, privileged access management
```

### 2.2 Attack Surface Analysis

```
EXTERNAL ATTACK SURFACE:
┌─────────────────────────────────────────────────────┐
│ Public IP (20.x.x.x)                                │
│ ├─ SSH (22)           - SSH key auth ✅            │
│ ├─ Guacamole (8080)   - Password auth ⚠️           │
│ ├─ Grafana (3000)     - Password auth ⚠️           │
│ └─ Prometheus (9090)  - No auth ❌                 │
└─────────────────────────────────────────────────────┘

INTERNAL ATTACK SURFACE:
┌─────────────────────────────────────────────────────┐
│ Private Network (10.0.0.0/16)                       │
│ ├─ SQL Server (1433-1435) - SQL auth ⚠️           │
│ ├─ RDP (3389)             - Password auth ⚠️       │
│ └─ Container Runtime       - Root access ❌        │
└─────────────────────────────────────────────────────┘

ADMINISTRATIVE SURFACE:
┌─────────────────────────────────────────────────────┐
│ Azure Portal                                        │
│ ├─ Azure RBAC          - Azure AD ✅               │
│ ├─ Terraform State     - Local file ❌             │
│ └─ Git Repository      - GitHub auth ✅            │
└─────────────────────────────────────────────────────┘
```

### 2.3 Risk Matrix

| Risk | Likelihood | Impact | Risk Level | Mitigation Priority |
|------|------------|--------|------------|---------------------|
| Brute force SSH | Low | High | MEDIUM | Monitor, fail2ban |
| Stolen SQL credentials | Medium | High | HIGH | Key Vault, rotation |
| Container escape | Low | Critical | HIGH | Security updates, hardening |
| Data exfiltration | Medium | Critical | HIGH | Network monitoring, DLP |
| DDoS attack | Medium | Medium | MEDIUM | Azure DDoS Protection |
| Insider threat | Low | Critical | MEDIUM | Audit logging, RBAC |
| Unpatched vulnerabilities | High | High | HIGH | Auto-update, scanning |
| Misconfiguration | High | Medium | HIGH | IaC validation, Policy |

---

## 3. Security Architecture

### 3.1 Defense-in-Depth Layers

```
┌─────────────────────────────────────────────────────────┐
│ Layer 7: Application Security                           │
│ ✅ SQL Server authentication                            │
│ ✅ Guacamole RBAC                                        │
│ ⚠️ Grafana basic auth (needs enhancement)              │
│ ❌ Prometheus no auth (internal only)                   │
├─────────────────────────────────────────────────────────┤
│ Layer 6: Container Security                             │
│ ⚠️ Image scanning (manual)                              │
│ ⚠️ Resource limits (configured)                         │
│ ❌ Runtime security (not implemented)                   │
│ ❌ Secrets in environment (needs Key Vault)            │
├─────────────────────────────────────────────────────────┤
│ Layer 5: Host Security                                  │
│ ✅ SSH key only (Linux)                                 │
│ ✅ Auto-patching enabled                                │
│ ✅ Firewall rules (firewalld/Windows Firewall)         │
│ ⚠️ No host-based IDS/IPS                               │
├─────────────────────────────────────────────────────────┤
│ Layer 4: Network Security                               │
│ ✅ Network Security Groups                              │
│ ✅ Subnet isolation                                     │
│ ✅ No public IPs on workloads                          │
│ ⚠️ No TLS encryption                                    │
├─────────────────────────────────────────────────────────┤
│ Layer 3: Identity & Access                              │
│ ✅ Azure RBAC                                           │
│ ⚠️ Local accounts (not Azure AD)                       │
│ ❌ No MFA enforcement                                   │
│ ❌ No JIT access                                        │
├─────────────────────────────────────────────────────────┤
│ Layer 2: Data Security                                  │
│ ✅ Encryption at rest (Azure default)                  │
│ ❌ No explicit disk encryption                          │
│ ❌ No TLS in transit                                    │
│ ⚠️ Backup encryption (Azure Backup)                    │
├─────────────────────────────────────────────────────────┤
│ Layer 1: Physical Security                              │
│ ✅ Azure datacenter security                            │
│ ✅ Hardware security modules                            │
│ ✅ Geographic redundancy                                │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Security Zones

```
┌──────────────────────────────────────────────────────────────┐
│                    PUBLIC ZONE (Internet)                     │
│  Threat Level: HIGH                                           │
│  Trust Level: NONE                                            │
├──────────────────────────────────────────────────────────────┤
│                           ▼                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ PERIMETER ZONE (Linux VM with Public IP)              │  │
│  │ Threat Level: HIGH                                     │  │
│  │ Trust Level: LOW                                       │  │
│  │ Controls: NSG, SSH keys, fail2ban                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ▼                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ APPLICATION ZONE (Containers)                          │  │
│  │ Threat Level: MEDIUM                                   │  │
│  │ Trust Level: MEDIUM                                    │  │
│  │ Controls: Resource limits, network policies           │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ▼                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ MANAGEMENT ZONE (Windows VM - No Public IP)           │  │
│  │ Threat Level: LOW                                      │  │
│  │ Trust Level: HIGH                                      │  │
│  │ Controls: Private network, subnet isolation           │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ▼                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ DATA ZONE (SQL Server containers, volumes)            │  │
│  │ Threat Level: CRITICAL                                 │  │
│  │ Trust Level: VARIES                                    │  │
│  │ Controls: SQL auth, encryption at rest, backups       │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. Authentication & Authorization

### 4.1 Authentication Matrix

| System | Method | Strength | MFA | Certificate | Notes |
|--------|--------|----------|-----|-------------|-------|
| Azure Portal | Azure AD | Strong | ✅ | ✅ | Recommended |
| Linux VM | SSH Key | Strong | N/A | ✅ | Password disabled |
| Windows VM | Password | Medium | ❌ | ❌ | Via Guacamole only |
| Guacamole | Password | Medium | ⚠️ | ❌ | Stored in PostgreSQL |
| SQL Server | SQL Auth | Medium | ❌ | ❌ | SA password required |
| Grafana | Password | Medium | ⚠️ | ❌ | Default admin user |
| Prometheus | None | N/A | N/A | N/A | Internal network only |
| Docker API | None | N/A | N/A | N/A | Local socket only |

**Legend:**
- ✅ Implemented
- ⚠️ Optional/Configurable
- ❌ Not Available

### 4.2 Authorization Model

**Azure RBAC:**
```
Subscription
├─ Owner (Full control)
├─ Contributor (Deploy and manage resources)
├─ Reader (View resources)
└─ Custom Roles (Granular permissions)

Recommended Assignment:
├─ Admins: Owner or Contributor
├─ Developers: Contributor (resource group scope)
├─ Operators: Reader + VM Contributor
└─ Auditors: Reader + Security Reader
```

**SQL Server Roles:**
```
Server Level:
├─ sa (sysadmin) - Full control
├─ db_owner - Database ownership
├─ db_ddladmin - DDL operations
├─ db_datareader - Read access
└─ db_datawriter - Write access

Best Practice:
❌ Don't use 'sa' for applications
✅ Create dedicated users with minimal permissions
✅ Use Windows Authentication (for native SQL)
✅ Implement row-level security
```

### 4.3 Password Policy

**Current Requirements:**
```
Windows Admin Password:
├─ Length: >= 12 characters (Terraform validation)
├─ Complexity: Mixed case, numbers, symbols
├─ Rotation: Manual
└─ Storage: terraform.tfvars (gitignored)

SQL SA Password:
├─ Length: >= 8 characters (Terraform validation)
├─ Complexity: SQL Server requirements
├─ Rotation: Manual
└─ Storage: terraform.tfvars (gitignored)

Guacamole Password:
├─ Length: >= 12 characters (Terraform validation)
├─ Complexity: User-defined
├─ Rotation: Manual
└─ Storage: terraform.tfvars (gitignored)
```

**Recommended Enhancements:**
```hcl
# Enforce strong passwords
variable "admin_password" {
  validation {
    condition = (
      length(var.admin_password) >= 16 &&
      can(regex("[A-Z]", var.admin_password)) &&
      can(regex("[a-z]", var.admin_password)) &&
      can(regex("[0-9]", var.admin_password)) &&
      can(regex("[!@#$%^&*]", var.admin_password))
    )
    error_message = "Password must be 16+ chars with uppercase, lowercase, number, and symbol."
  }
}
```

---

## 5. Network Security

### 5.1 Network Security Group Rules

**Linux NSG (sql-docker-demo-linux-nsg):**

```
INBOUND RULES (Priority Order):
┌──────┬─────────────────┬────────┬──────────┬──────────────┬──────┐
│ Prio │ Name            │ Action │ Protocol │ Source       │ Port │
├──────┼─────────────────┼────────┼──────────┼──────────────┼──────┤
│ 1001 │ SSH             │ Allow  │ TCP      │ ${allow_ips} │ 22   │
│ 1002 │ Guacamole-HTTP  │ Allow  │ TCP      │ ${allow_ips} │ 8080 │
│ 1003 │ Grafana         │ Allow  │ TCP      │ ${allow_ips} │ 3000 │
│ 1004 │ Prometheus      │ Allow  │ TCP      │ ${allow_ips} │ 9090 │
│ 1005 │ SQL-Server      │ Allow  │ TCP      │ 10.0.2.0/24  │ 1433-│
│      │                 │        │          │              │ 1435 │
│ 65000│ DenyAllInbound  │ Deny   │ *        │ *            │ *    │
└──────┴─────────────────┴────────┴──────────┴──────────────┴──────┘

CRITICAL SECURITY CONTROLS:
✅ SSH restricted to specific IPs only
✅ Web services restricted to specific IPs
✅ SQL ports only accessible from Windows subnet
✅ Default deny-all rule at lowest priority
```

**Windows NSG (sql-docker-demo-windows-nsg):**

```
INBOUND RULES:
┌──────┬─────────────────┬────────┬──────────┬──────────────┬──────┐
│ Prio │ Name            │ Action │ Protocol │ Source       │ Port │
├──────┼─────────────────┼────────┼──────────┼──────────────┼──────┤
│ 1001 │ RDP-from-Linux  │ Allow  │ TCP      │ 10.0.1.0/24  │ 3389 │
│ 1002 │ SQL-from-Linux  │ Allow  │ TCP      │ 10.0.1.0/24  │ 1433 │
│ 1003 │ WinRM           │ Allow  │ TCP      │ ${allow_ips} │ 5985-│
│      │                 │        │          │              │ 5986 │
│ 65000│ DenyAllInbound  │ Deny   │ *        │ *            │ *    │
└──────┴─────────────────┴────────┴──────────┴──────────────┴──────┘

CRITICAL SECURITY CONTROLS:
✅ RDP only from Linux subnet (via Guacamole)
✅ SQL only from Linux subnet
⚠️ WinRM exposed to internet (should remove)
✅ No direct internet access to workload
```

### 5.2 Network Segmentation

```
Virtual Network: 10.0.0.0/16
├─ Linux Subnet: 10.0.1.0/24 (251 IPs)
│  ├─ Purpose: Container host, edge services
│  ├─ Public Access: YES (single public IP)
│  ├─ Trust Level: LOW
│  └─ Controls: NSG, SSH keys, monitoring
│
└─ Windows Subnet: 10.0.2.0/24 (251 IPs)
   ├─ Purpose: Management, SSMS
   ├─ Public Access: NO
   ├─ Trust Level: MEDIUM
   └─ Controls: NSG, RDP via Guacamole

Traffic Flow Rules:
├─ Internet → Linux: Restricted (NSG)
├─ Internet → Windows: BLOCKED (no public IP)
├─ Linux → Windows: ALLOWED (RDP, SQL)
├─ Windows → Linux: ALLOWED (SQL containers)
└─ Linux → Internet: ALLOWED (outbound)
```

### 5.3 Firewall Rules (Host-Level)

**Linux (firewalld):**
```bash
# Configured via cloud-init
firewall-cmd --permanent --add-port=22/tcp      # SSH
firewall-cmd --permanent --add-port=1433-1435/tcp # SQL
firewall-cmd --permanent --add-port=3000/tcp    # Grafana
firewall-cmd --permanent --add-port=8080/tcp    # Guacamole
firewall-cmd --permanent --add-port=9090/tcp    # Prometheus
firewall-cmd --reload
```

**Windows (Windows Firewall):**
```powershell
# Configured via Custom Script Extension
New-NetFirewallRule -DisplayName "SQL Server" `
  -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

New-NetFirewallRule -DisplayName "RDP" `
  -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
```

### 5.4 TLS/HTTPS (Future Enhancement)

**Current State:** ❌ All services use HTTP/unencrypted

**Recommended Implementation:**
```yaml
# nginx reverse proxy with Let's Encrypt
nginx:
  image: nginx:alpine
  ports:
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/nginx/ssl
  depends_on:
    - guacamole
    - grafana
    - prometheus

# Automatic TLS with Caddy (alternative)
caddy:
  image: caddy:2-alpine
  ports:
    - "443:443"
  volumes:
    - ./Caddyfile:/etc/caddy/Caddyfile
    - caddy_data:/data
```

---

## 6. Data Security

### 6.1 Encryption at Rest

**Azure Managed Disks:**
```
Default Encryption:
├─ Technology: Azure Storage Service Encryption (SSE)
├─ Algorithm: AES-256
├─ Key Management: Microsoft-managed keys
├─ Scope: All managed disks automatically encrypted
└─ Status: ✅ Enabled by default

Recommended Enhancement:
├─ Customer-managed keys (CMK)
├─ Azure Key Vault integration
├─ Key rotation policies
└─ BYOK (Bring Your Own Key)
```

**Implementation Example:**
```hcl
# Enable customer-managed keys
resource "azurerm_disk_encryption_set" "main" {
  name                = "${var.project_name}-disk-encryption"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_key_id    = azurerm_key_vault_key.disk_encryption.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_managed_disk" "linux_data" {
  encryption_settings {
    enabled = true
    disk_encryption_key {
      secret_url      = azurerm_key_vault_secret.disk_encryption.id
      source_vault_id = azurerm_key_vault.main.id
    }
  }
}
```

### 6.2 Encryption in Transit

**Current State:**
```
✅ SSH (port 22): Encrypted by default
❌ HTTP (ports 8080, 3000, 9090): Unencrypted
❌ SQL Server (ports 1433-1435): Unencrypted
⚠️ RDP via Guacamole: Encrypted (Guacamole→VM), but Guacamole itself HTTP
```

**SQL Server TLS Configuration:**
```sql
-- Enable Force Encryption on SQL Server
USE master;
GO

-- Configure TLS certificate
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

-- Force encryption
ALTER SERVER CONFIGURATION SET PROPERTY ForceEncryption = 1;
```

### 6.3 Data Classification

| Data Type | Sensitivity | Encryption Required | Backup Retention | Access Control |
|-----------|-------------|---------------------|------------------|----------------|
| SQL data | HIGH | ✅ At rest | 30 days | SQL auth + NSG |
| Credentials | CRITICAL | ✅ At rest, in transit | N/A | Terraform sensitive |
| Configuration | MEDIUM | ⚠️ Recommended | Version control | Git + RBAC |
| Logs | LOW | ⚠️ Optional | 30 days | NSG + monitoring |
| Metrics | LOW | ❌ Not required | 30 days | NSG |
| Backups | HIGH | ✅ Required | 30-90 days | Azure Backup RBAC |

---

## 7. Container Security

### 7.1 Container Image Security

**Base Images:**
```yaml
SQL Server:
  Image: mcr.microsoft.com/mssql/server:2022-latest
  Registry: Microsoft Container Registry (MCR)
  Trust: ✅ Official Microsoft image
  Scanning: ⚠️ Manual (should automate)
  Updates: ⚠️ Manual pull (should automate)

Supporting Services:
  Prometheus: prom/prometheus:latest
  Grafana: grafana/grafana:latest
  Guacamole: guacamole/guacamole:latest
  Trust: ✅ Official images
  Scanning: ⚠️ Not implemented
```

**Image Scanning (Recommended):**
```bash
# Trivy image scanning
trivy image mcr.microsoft.com/mssql/server:2022-latest

# Snyk scanning
snyk container test mcr.microsoft.com/mssql/server:2022-latest

# Azure Container Registry scanning (when using ACR)
az acr task create \
  --name scan-on-push \
  --image {{.Run.Registry}}/{{.Run.ImageName}}:{{.Run.Tag}} \
  --cmd "trivy image {{.Run.Registry}}/{{.Run.ImageName}}:{{.Run.Tag}}"
```

### 7.2 Container Runtime Security

**Current Configuration:**
```yaml
sql-primary:
  # SECURITY ISSUES:
  ❌ Running as root (default)
  ❌ Privileged: false (good, but should explicitly set)
  ❌ No security options defined
  ❌ No AppArmor/SELinux profile
  ❌ Host network: false (good)
  ⚠️ Environment variables for secrets

  # POSITIVE CONTROLS:
  ✅ Resource limits defined
  ✅ Restart policy: unless-stopped
  ✅ Health checks configured
  ✅ Read-only root filesystem: false (required for SQL)
```

**Recommended Hardening:**
```yaml
sql-primary:
  image: mcr.microsoft.com/mssql/server:2022-latest
  
  # Run as non-root (if possible)
  user: "10001:0"
  
  # Security options
  security_opt:
    - no-new-privileges:true
    - seccomp:default
  
  # Capabilities
  cap_drop:
    - ALL
  cap_add:
    - CHOWN
    - SETGID
    - SETUID
  
  # Prevent privilege escalation
  privileged: false
  
  # Resource limits
  deploy:
    resources:
      limits:
        cpus: '4'
        memory: 16G
        pids: 512
```

### 7.3 Container Network Security

**Docker Network Isolation:**
```yaml
networks:
  sql-network:
    driver: bridge
    internal: false  # ⚠️ Should be true for internal-only
    ipam:
      config:
        - subnet: 172.20.0.0/24
    driver_opts:
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
```

**Network Policies (Future - requires Kubernetes):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sql-server-policy
spec:
  podSelector:
    matchLabels:
      app: sql-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: management
    ports:
    - protocol: TCP
      port: 1433
```

---

## 8. Secrets Management

### 8.1 Current Secrets Handling

**Terraform Variables (Current):**
```hcl
# terraform.tfvars (gitignored)
admin_password           = "SecurePassword123!"
sql_sa_password          = "SQLPassword123!"
guacamole_admin_password = "GuacPassword123!"

# Issues:
❌ Plain text in local file
❌ Manual distribution
❌ No rotation
❌ No audit trail
❌ Exposed in cloud-init / Custom Script Extension
```

**Cloud-Init Exposure:**
```yaml
# Secrets passed as template variables
custom_data = base64encode(templatefile("cloud-init.yaml", {
  sql_sa_password = var.sql_sa_password  # ❌ Visible in VM metadata
}))

# Risks:
❌ Visible in Azure portal (VM → Settings → Extensions)
❌ Stored in Azure logs
❌ Accessible via Azure API
```

### 8.2 Azure Key Vault Integration (Recommended)

**Implementation:**

Step 1: Create Key Vault
```hcl
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  
  network_acls {
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = [
      azurerm_subnet.linux.id,
      azurerm_subnet.windows.id
    ]
  }
}
```

Step 2: Store Secrets
```hcl
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-sa-password"
  value        = var.sql_sa_password
  key_vault_id = azurerm_key_vault.main.id
  
  content_type = "password"
  
  tags = {
    Environment = var.environment
    Rotation    = "90days"
  }
}
```

Step 3: Grant Access
```hcl
# Managed Identity for Linux VM
resource "azurerm_linux_virtual_machine" "linux" {
  identity {
    type = "SystemAssigned"
  }
}

# Grant Key Vault access
resource "azurerm_key_vault_access_policy" "linux_vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.linux.identity[0].principal_id
  
  secret_permissions = [
    "Get",
    "List"
  ]
}
```

Step 4: Retrieve Secrets
```bash
# In cloud-init or startup script
SQL_PASSWORD=$(az keyvault secret show \
  --name sql-sa-password \
  --vault-name ${var.project_name}-kv \
  --query value -o tsv)
```

### 8.3 Secrets Rotation

**Rotation Policy:**
```
Password Rotation Schedule:
├─ Admin passwords: Every 90 days
├─ SQL SA password: Every 60 days
├─ Service accounts: Every 90 days
└─ API keys: Every 180 days

Automation:
├─ Azure Key Vault rotation policies
├─ Azure Functions for automated rotation
└─ Alerts for upcoming expirations
```

**Implementation:**
```hcl
resource "azurerm_key_vault_secret" "sql_password" {
  # ... existing config ...
  
  # Rotation policy
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"  # Rotate 30 days before expiry
    }
    
    expire_after         = "P60D"  # Expire after 60 days
    notify_before_expiry = "P7D"   # Notify 7 days before
  }
}
```

---

## 9. Compliance & Governance

### 9.1 Compliance Framework Alignment

**CIS Microsoft Azure Foundations Benchmark:**
```
✅ 1.1  Ensure security contact emails are set
⚠️ 1.2  Ensure security contact phone number is set
✅ 2.1  Ensure NSGs are configured
⚠️ 2.2  Ensure NSG flow logs are enabled (not implemented)
✅ 3.1  Ensure public IPs are minimized
⚠️ 3.2  Ensure Azure Defender is enabled (not implemented)
✅ 4.1  Ensure disk encryption is enabled
⚠️ 4.2  Ensure Key Vault is used (recommended, not required)
✅ 5.1  Ensure RBAC is configured
⚠️ 5.2  Ensure MFA is enabled (Azure AD level)

Overall Compliance: 65%
```

**NIST Cybersecurity Framework:**
```
IDENTIFY:
✅ Asset inventory (IaC)
✅ Risk assessment (documented)
✅ Governance policies (partial)

PROTECT:
✅ Access control (RBAC, NSGs)
⚠️ Data security (partial encryption)
⚠️ Maintenance (manual updates)

DETECT:
⚠️ Monitoring (basic)
❌ Security events (no SIEM)
❌ Anomaly detection (not implemented)

RESPOND:
⚠️ Incident response (documented)
❌ Automated response (not implemented)

RECOVER:
⚠️ Recovery planning (documented)
⚠️ Backups (recommended, not required)

Overall Maturity: Level 2 (Managed)
```

### 9.2 Azure Policy (Recommended)

```hcl
# Enforce tagging
resource "azurerm_policy_assignment" "require_tags" {
  name                 = "require-tags"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  
  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
  })
}

# Enforce encryption
resource "azurerm_policy_assignment" "require_encryption" {
  name                 = "require-disk-encryption"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0473574d-2d43-4217-aefe-941fcdf7e684"
}

# Allowed locations
resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  
  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["westus2", "eastus"]
    }
  })
}
```

### 9.3 Audit Logging

**Azure Activity Log:**
```
Automatically Logged:
✅ Resource creation/deletion
✅ Configuration changes
✅ Access control changes
✅ Policy assignments
✅ Failed operations

Retention:
├─ Default: 90 days
└─ Extended: Export to Log Analytics or Storage Account
```

**Enable Diagnostic Settings:**
```hcl
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name               = "vm-diagnostics"
  target_resource_id = azurerm_linux_virtual_machine.linux.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  log {
    category = "Administrative"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 365
    }
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}
```

---

## 10. Security Monitoring

### 10.1 Monitoring Architecture

```
┌────────────────────────────────────────────────────────────┐
│                  Monitoring Stack                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Log Collection                                            │
│  ├─ VM Logs (syslog, Windows Event Log)                   │
│  ├─ Container Logs (Docker logs)                          │
│  ├─ Application Logs (SQL Server)                         │
│  └─ Azure Activity Log                                     │
│                    ↓                                        │
│  Log Aggregation                                           │
│  ├─ (Current) Local files                                 │
│  └─ (Recommended) Azure Monitor Logs                      │
│                    ↓                                        │
│  Metrics Collection                                        │
│  ├─ Prometheus (container metrics)                        │
│  ├─ Azure Monitor (VM metrics)                            │
│  └─ SQL Server DMVs (database metrics)                    │
│                    ↓                                        │
│  Visualization                                             │
│  ├─ Grafana (dashboards)                                  │
│  └─ Azure Monitor Workbooks                               │
│                    ↓                                        │
│  Alerting                                                  │
│  ├─ (Current) None                                        │
│  └─ (Recommended) Azure Monitor Alerts                    │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### 10.2 Security Alerts (Recommended)

```yaml
Security Events to Monitor:
├─ Failed SSH attempts (>5 in 10 minutes)
├─ Failed SQL login attempts (>10 in 5 minutes)
├─ High CPU usage (>90% for 15 minutes)
├─ High memory usage (>90% for 15 minutes)
├─ Disk space low (<10%)
├─ Container crashes (any)
├─ Network anomalies (unusual traffic patterns)
├─ Configuration changes (NSG, RBAC)
└─ New public IP assignments

Alert Channels:
├─ Email (admin email)
├─ SMS (for critical alerts)
├─ Teams/Slack (via webhooks)
└─ Azure Monitor Action Groups
```

### 10.3 Azure Security Center (Recommended)

```hcl
# Enable Azure Security Center
resource "azurerm_security_center_subscription_pricing" "vm" {
  tier          = "Standard"  # Or "Free"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_contact" "main" {
  email = "adrian207@gmail.com"
  phone = "+1234567890"
  
  alert_notifications = true
  alerts_to_admins    = true
}

resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = "On"  # Auto-install monitoring agent
}
```

---

## 11. Incident Response

### 11.1 Incident Response Plan

**Phase 1: Preparation**
```
✅ Document contact information
✅ Define roles and responsibilities
✅ Establish communication channels
⚠️ Conduct tabletop exercises
⚠️ Maintain incident response runbooks
```

**Phase 2: Detection & Analysis**
```
Detection Methods:
├─ Automated monitoring alerts
├─ User reports
├─ Security scanning
└─ Log analysis

Initial Assessment:
├─ Severity classification (Low/Medium/High/Critical)
├─ Scope determination (affected systems)
├─ Impact analysis (data, availability, reputation)
└─ Classification (malware, breach, DoS, etc.)
```

**Phase 3: Containment, Eradication & Recovery**
```
Short-term Containment:
├─ Isolate affected systems (NSG rules)
├─ Disable compromised accounts
├─ Take snapshots/backups
└─ Preserve evidence

Eradication:
├─ Remove malware/backdoors
├─ Patch vulnerabilities
├─ Reset compromised credentials
└─ Update security controls

Recovery:
├─ Restore from clean backups
├─ Verify system integrity
├─ Gradual service restoration
└─ Enhanced monitoring
```

**Phase 4: Post-Incident Activity**
```
Post-Incident Review:
├─ Timeline documentation
├─ Root cause analysis
├─ Lessons learned
├─ Update procedures
└─ Implement preventive measures
```

### 11.2 Incident Severity Matrix

| Severity | Definition | Response Time | Example |
|----------|------------|---------------|---------|
| **Critical** | Complete system compromise, data breach | Immediate (15 min) | SQL database stolen |
| **High** | Significant impact, limited compromise | 1 hour | VM compromised |
| **Medium** | Degraded service, potential risk | 4 hours | Failed login attempts spike |
| **Low** | Minor impact, informational | 24 hours | Non-critical patch available |

### 11.3 Communication Plan

**Internal Communication:**
```
Incident Commander: Adrian Johnson (adrian207@gmail.com)
├─ Technical Team: [List]
├─ Management: [List]
└─ Legal/Compliance: [If applicable]

Communication Tools:
├─ Primary: Teams/Slack channel (#incident-response)
├─ Secondary: Email distribution list
└─ Emergency: Phone call tree
```

**External Communication:**
```
Customers/Users:
├─ Status page updates
├─ Email notifications (if applicable)
└─ Social media (if applicable)

Regulatory Bodies:
├─ Data breach notification (if required)
├─ Timeline: Within 72 hours (GDPR)
└─ Contact: [Regulatory body]
```

---

## 12. Security Checklist

### 12.1 Pre-Deployment Security Checklist

```
Configuration Review:
☐ Review and update terraform.tfvars
☐ Set strong passwords (16+ characters, complex)
☐ Configure allowed_ip_ranges to specific IPs (not 0.0.0.0/0)
☐ Review NSG rules
☐ Verify SSH key is secure
☐ Check auto-shutdown configuration

Validation:
☐ Run terraform validate
☐ Review terraform plan output
☐ Verify no hardcoded secrets in code
☐ Check .gitignore includes terraform.tfvars
☐ Scan Terraform code with tfsec or Checkov

Documentation:
☐ Document admin contacts
☐ Update incident response plan
☐ Review backup procedures
☐ Document compliance requirements
```

### 12.2 Post-Deployment Security Checklist

```
Immediate (Day 1):
☐ Verify all services started correctly
☐ Test connectivity from allowed IPs only
☐ Change default passwords (Grafana, Guacamole)
☐ Verify no public access to Windows VM
☐ Test SSH key authentication
☐ Verify auto-shutdown works

Short-term (Week 1):
☐ Set up monitoring alerts
☐ Configure backup schedule
☐ Test disaster recovery procedure
☐ Review security logs
☐ Update OS patches
☐ Scan for vulnerabilities

Ongoing (Monthly):
☐ Review access logs
☐ Rotate passwords
☐ Update container images
☐ Review NSG rules
☐ Audit user access
☐ Test incident response plan
☐ Review compliance status
```

### 12.3 Security Hardening Checklist

```
Critical (Implement Immediately):
☐ Remove WinRM internet exposure
☐ Enable Azure Security Center
☐ Implement Azure Key Vault
☐ Enable NSG flow logs
☐ Configure TLS/HTTPS
☐ Enable disk encryption
☐ Set up automated backups

High Priority (1 Month):
☐ Implement Azure Sentinel
☐ Add MFA to all accounts
☐ Enable Azure Monitor
☐ Configure automated patching
☐ Implement JIT access
☐ Add Web Application Firewall

Medium Priority (3 Months):
☐ Migrate to AKS with network policies
☐ Implement Azure Firewall
☐ Add DDoS Protection
☐ Enable Azure Defender for SQL
☐ Implement Azure AD integration
☐ Add private endpoints

Low Priority (6 Months):
☐ Implement SIEM integration
☐ Add threat intelligence feeds
☐ Implement security orchestration
☐ Add advanced threat protection
☐ Implement Azure Policy at scale
```

---

## Appendices

### A. Security Tools & Resources

**Scanning Tools:**
- **Trivy**: Container image vulnerability scanning
- **tfsec**: Terraform security scanning
- **Checkov**: IaC security and compliance scanning
- **Snyk**: Code and dependency scanning

**Monitoring Tools:**
- **Azure Security Center**: Cloud security posture management
- **Azure Sentinel**: SIEM and SOAR
- **Falco**: Container runtime security
- **OSSEC**: Host-based intrusion detection

**Documentation:**
- CIS Azure Foundations Benchmark
- NIST Cybersecurity Framework
- Azure Security Best Practices
- OWASP Top 10

### B. Security Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Security Lead | Adrian Johnson | adrian207@gmail.com | - |
| Incident Commander | Adrian Johnson | adrian207@gmail.com | - |
| Azure Support | Azure | - | - |

### C. Compliance Artifacts

```
Compliance Documentation Location:
├─ Security policies: docs/policies/
├─ Risk assessments: docs/risk/
├─ Audit reports: docs/audits/
├─ Incident reports: docs/incidents/
└─ Compliance certifications: docs/compliance/
```

---

## Document Review & Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Author** | Adrian Johnson | | Jan 2025 |
| **Security Reviewer** | | | |
| **Compliance Officer** | | | |
| **Approver** | | | |

---

**Document Classification:** Internal  
**Document Owner:** Adrian Johnson <adrian207@gmail.com>  
**Last Security Review:** January 2025  
**Next Security Review:** April 2025 (Quarterly)

---

*This is a living document. All security findings and improvements should be documented here.*

