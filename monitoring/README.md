# Monitoring Stack for SQL Server Containers

This directory contains Prometheus and Grafana configurations for monitoring SQL Server containers.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **SQL Server Exporter**: SQL Server metrics (coming soon)

## Access

- **Grafana**: `http://<linux-public-ip>:3000`
  - Username: `admin`
  - Password: `admin` (change on first login)

- **Prometheus**: `http://<linux-public-ip>:9090`

## Pre-configured Dashboards (Coming Soon)

1. **SQL Server Overview**
   - CPU and memory usage
   - Active connections
   - Query performance
   - Disk I/O

2. **High Availability Status**
   - Replication lag
   - Log shipping status
   - Availability Group health
   - Failover events

3. **Docker Container Metrics**
   - Container CPU/memory
   - Network traffic
   - Disk usage

## Custom Metrics

### SQL Server Performance Counters

```sql
-- Query to expose SQL Server metrics
SELECT 
    counter_name,
    instance_name,
    cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name IN (
    'User Connections',
    'Batch Requests/sec',
    'SQL Compilations/sec',
    'Page life expectancy'
);
```

### Container Health Checks

```bash
# Check container health status
docker inspect sql-primary --format='{{.State.Health.Status}}'

# View health check logs
docker inspect sql-primary --format='{{json .State.Health}}' | jq
```

## Alerts (Coming Soon)

Planned alert rules:

- SQL Server down
- High CPU usage (>80%)
- High memory usage (>90%)
- Replication lag >1 minute
- Failed login attempts spike
- Long-running queries
- Disk space low

## Future Enhancements

- [ ] SQL Server Prometheus exporter integration
- [ ] Custom Grafana dashboards
- [ ] Alert manager configuration
- [ ] Log aggregation with Loki
- [ ] Distributed tracing

