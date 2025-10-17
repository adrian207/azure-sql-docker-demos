# Ansible Automation (Coming Soon)

This directory will contain Ansible playbooks and roles for automated configuration of the SQL Server demo environment.

## Planned Playbooks

### 1. Initial Setup
- Configure Linux VM post-deployment
- Install additional packages
- Configure Docker and containers
- Set up monitoring

### 2. SQL Server Configuration
- Initialize SQL Server instances
- Create databases
- Configure users and permissions
- Set up maintenance jobs

### 3. High Availability Setup
- Configure log shipping
- Set up transactional replication
- Deploy Always On Availability Groups
- Configure failover automation

### 4. Monitoring Configuration
- Deploy Prometheus exporters
- Configure Grafana dashboards
- Set up alerts
- Configure log forwarding

## Future Structure

```
ansible/
├── playbooks/
│   ├── site.yml                    # Main playbook
│   ├── setup-docker.yml            # Docker setup
│   ├── deploy-sql-containers.yml   # SQL containers
│   ├── configure-log-shipping.yml  # Log shipping
│   ├── configure-replication.yml   # Replication
│   └── configure-always-on.yml     # Always On AG
│
├── roles/
│   ├── common/                     # Common tasks
│   ├── docker/                     # Docker installation
│   ├── sql-server/                 # SQL Server config
│   ├── monitoring/                 # Prometheus/Grafana
│   └── guacamole/                  # Guacamole setup
│
├── inventory/
│   ├── hosts.yml                   # Inventory file
│   └── group_vars/                 # Variables
│
└── README.md                       # This file
```

## Why Ansible?

- **Idempotent**: Safe to run multiple times
- **Repeatable**: Consistent configuration
- **Version Controlled**: Infrastructure as Code
- **Agentless**: SSH-based, no agents needed
- **Extensible**: Large module ecosystem

## Coming Soon

This section is under development. For now, all configuration is handled by:
- Terraform (infrastructure)
- Cloud-init (Linux VM initial setup)
- CustomScriptExtension (Windows VM initial setup)
- Docker Compose (container orchestration)

Ansible playbooks will be added in future updates to provide more flexibility and automation options.

