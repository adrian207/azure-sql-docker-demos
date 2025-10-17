# Docker Configurations for SQL Server Demos

This directory contains Docker Compose configurations for different SQL Server high availability scenarios.

## Quick Start

All SQL Server containers are automatically deployed when the Linux VM starts via cloud-init.

### Access SQL Server

**From Windows VM (via SSMS):**
```
Server: <linux-private-ip>,1433     # Primary
Server: <linux-private-ip>,1434     # Secondary  
Server: <linux-private-ip>,1435     # Witness
Login: sa
Password: <sql_sa_password from terraform.tfvars>
```

**From Linux VM (SSH):**
```bash
# Connect to primary
docker exec -it sql-primary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourPassword'

# Connect to secondary
docker exec -it sql-secondary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourPassword'

# View container logs
docker logs sql-primary
docker logs sql-secondary
```

## Container Architecture

```
sql-primary    → Port 1433 (Main database server)
sql-secondary  → Port 1434 (Standby/replica)
sql-witness    → Port 1435 (Quorum for Always On AG)

guacamole      → Port 8080 (Web-based RDP/SSH)
grafana        → Port 3000 (Monitoring dashboards)
prometheus     → Port 9090 (Metrics collection)
```

## Demo Scenarios

### 1. Log Shipping (feat/sql-log-shipping branch)

**Setup:**
```bash
cd /opt/sql-docker/log-shipping
docker-compose up -d
./configure-log-shipping.sh
```

**What it demonstrates:**
- Automated transaction log backups
- Log restore on secondary server
- Manual failover process
- Monitoring backup/restore jobs

---

### 2. Transactional Replication (feat/sql-transactional-replication branch)

**Setup:**
```bash
cd /opt/sql-docker/replication
docker-compose up -d
./setup-replication.sh
```

**What it demonstrates:**
- Publisher → Subscriber data flow
- Real-time data synchronization
- Replication monitoring
- Conflict resolution

---

### 3. Always On Availability Groups (feat/sql-always-on-ag branch)

**Setup:**
```bash
cd /opt/sql-docker/always-on
docker-compose up -d
./configure-ag.sh
```

**What it demonstrates:**
- 3-node cluster configuration
- Automatic failover
- Read-only secondary replicas
- Health monitoring

## Management Commands

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Check container logs
docker logs -f sql-primary

# Restart containers
docker-compose restart

# Stop all containers
docker-compose down

# Stop containers but keep volumes
docker-compose stop

# Remove everything (including volumes)
docker-compose down -v

# View container resource usage
docker stats
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs sql-primary

# Common issues:
# 1. Invalid SA password (must meet complexity requirements)
# 2. Port already in use
# 3. Insufficient memory

# Verify SA password meets requirements
echo $SA_PASSWORD
```

### Cannot connect to SQL Server

```bash
# Test from Linux VM
telnet localhost 1433

# Check if SQL is listening
docker exec sql-primary netstat -an | grep 1433

# Restart container
docker restart sql-primary
```

### Performance issues

```bash
# Check container resource limits
docker inspect sql-primary | grep -A 10 "Memory"

# View resource usage
docker stats sql-primary

# Increase container memory (edit docker-compose.yml)
deploy:
  resources:
    limits:
      memory: 8G
```

## Backup and Restore

### Manual Backup

```bash
# Create backup directory
mkdir -p /opt/sql-docker/backups

# Backup database
docker exec sql-primary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourPassword' \
  -Q "BACKUP DATABASE [YourDB] TO DISK='/var/opt/mssql/backup/yourdb.bak' WITH COMPRESSION"

# Copy backup to host
docker cp sql-primary:/var/opt/mssql/backup/yourdb.bak /opt/sql-docker/backups/
```

### Restore Backup

```bash
# Copy backup to container
docker cp /opt/sql-docker/backups/yourdb.bak sql-secondary:/var/opt/mssql/backup/

# Restore database
docker exec sql-secondary /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourPassword' \
  -Q "RESTORE DATABASE [YourDB] FROM DISK='/var/opt/mssql/backup/yourdb.bak' WITH REPLACE"
```

## Security Notes

⚠️ **These configurations are for DEMO purposes only!**

For production:
- Use Azure Key Vault for secrets
- Enable TLS encryption
- Use certificate-based authentication
- Implement least-privilege access
- Enable auditing and monitoring
- Use private container registries

## Additional Resources

- [SQL Server on Linux Containers](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SQL Server High Availability](https://learn.microsoft.com/en-us/sql/database-engine/sql-server-business-continuity-dr)

