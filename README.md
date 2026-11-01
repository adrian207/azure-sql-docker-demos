# azure-sql-docker-demos

Terraform that builds a small SQL Server lab in Azure: a Rocky Linux VM running three SQL Server 2022 containers with Prometheus, Grafana and Apache Guacamole, and a Windows Server 2022 VM with SQL Server Management Studio that you reach in the browser through Guacamole. Use it to practise log shipping, replication and Always On availability groups without installing anything locally.

## What it builds

| Resource | Details |
|---|---|
| **Linux VM** | Rocky Linux 9, `Standard_D8s_v3` by default, public IP, 512 GB data disk for Docker volumes |
| SQL Server containers | `sql-primary` (port 1433), `sql-secondary` (1434), `sql-witness` (1435): `mssql/server:2022-latest`, Developer edition; SQL Agent enabled on primary and secondary |
| Monitoring | Prometheus (9090) and Grafana (3000), each switchable with `enable_prometheus` / `enable_grafana` |
| Remote desktop | Apache Guacamole (8080) with a PostgreSQL backend and a ready-made RDP connection to the Windows VM |
| **Windows VM** | Windows Server 2022 Azure Edition, `Standard_D4s_v3`, no public IP; Chrome, Notepad++, 7-Zip and SSMS installed with Chocolatey |
| Native SQL Server (optional) | SQL Server 2022 Developer installed on the Windows VM when `deploy_windows_native_sql = true` (the default) |
| Network | One VNet with Linux and Windows subnets. SSH, Guacamole, Grafana and Prometheus are open only to `allowed_ip_ranges`; SQL and RDP to the Windows VM only from the Linux subnet |
| Cost control | Daily auto-shutdown of both VMs (19:00 Pacific by default) |

The Linux VM is configured by cloud-init (`terraform/cloud-init-linux.yaml`): it mounts the data disk, starts the containers with Docker Compose, initialises the Guacamole database and sets its admin password.

## Requirements

- Terraform 1.5 or later and the Azure CLI, signed in (`az login`) to a subscription where you can create VMs
- An SSH public key (default `~/.ssh/id_rsa.pub`, change with `ssh_public_key_path`)
- Quota for 12 vCPUs of the Dsv3 family in your region with the default sizes

## Quick start

```bash
git clone https://github.com/adrian207/azure-sql-docker-demos.git
cd azure-sql-docker-demos/terraform

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
#   allowed_ip_ranges        = ["<your public IP>/32"]   (curl ifconfig.me; 0.0.0.0/0 is rejected)
#   admin_password           = Windows VM password (12+ characters)
#   sql_sa_password          = SA password for the SQL containers
#   guacamole_admin_password = password for Guacamole (guacadmin) and Grafana (admin)

terraform init
terraform plan
terraform apply          # about 10-15 minutes, then a few more for cloud-init

terraform output connection_instructions
```

Then:

- **Guacamole:** `http://<linux_public_ip>:8080/guacamole`, sign in as `guacadmin` and open the *Windows Server 2022* connection
- **Grafana:** `http://<linux_public_ip>:3000`, user `admin`
- **SQL Server:** from SSMS on the Windows VM, connect to `<linux_private_ip>,1433` (or 1434, 1435) as `sa`
- **SSH:** `ssh <admin_username>@<linux_public_ip>`, then `docker ps`

`terraform destroy` removes everything.

### Separate environments

`terraform/environments/` has `dev`, `staging` and `prod` variable files. `scripts/deploy-env.sh` (or `deploy-env.ps1`) selects a Terraform workspace per environment and runs `plan`, `apply` or `destroy` with the matching file:

```bash
./scripts/deploy-env.sh dev plan
./scripts/deploy-env.sh dev apply
```

Fill in the empty passwords and `allowed_ip_ranges` in those files first. See [ENVIRONMENTS.md](ENVIRONMENTS.md).

## Configuration

Main variables (all in `terraform/variables.tf`):

| Variable | Default | Purpose |
|---|---|---|
| `allowed_ip_ranges` | (required) | Addresses that may reach SSH, Guacamole, Grafana and Prometheus |
| `admin_password`, `sql_sa_password`, `guacamole_admin_password` | (required) | Windows, SQL `sa`, and Guacamole/Grafana passwords |
| `location` | `westus2` | Azure region |
| `linux_vm_size`, `windows_vm_size` | `Standard_D8s_v3`, `Standard_D4s_v3` | VM sizes |
| `deploy_windows_native_sql` | `true` | Install SQL Server on the Windows VM as well |
| `enable_prometheus`, `enable_grafana` | `true` | Monitoring containers |
| `auto_shutdown_enabled`, `auto_shutdown_time`, `auto_shutdown_timezone` | `true`, `1900`, Pacific | Nightly shutdown |

Cost estimates are in [COST_BREAKDOWN.md](COST_BREAKDOWN.md) and [COST_ANALYSIS_CONTAINERS.md](COST_ANALYSIS_CONTAINERS.md); check current Azure pricing for your region.

## Repository layout

```
terraform/
  main.tf, network.tf, linux-vm.tf, windows-vm.tf, outputs.tf, variables.tf
  cloud-init-linux.yaml        Docker Compose stack, Prometheus config, Guacamole setup
  terraform.tfvars.example
  environments/                dev, staging and prod variable files
scripts/deploy-env.sh, .ps1    Workspace-per-environment wrapper around terraform
docs/                          Architecture and security notes
QUICKSTART.md, ENVIRONMENTS.md, COST_*.md
```

## Status and limitations

This is a lab, not a production design.

- **The SQL demos are manual.** The containers are provisioned, but log shipping, replication and availability groups are not configured for you. The `docker/` and `windows/` READMEs refer to helper scripts (`configure-ag.sh`, `setup-replication.sh`, `Test-SQLConnection.ps1` and others) that are not in this repository yet.
- **Monitoring is a starting point.** Prometheus scrapes the SQL ports directly, which do not serve metrics; add a SQL Server exporter for real data. Grafana has no dashboards preconfigured.
- `ansible/` and `monitoring/` contain only plans in their READMEs.
- Secrets are passed to the VMs through cloud-init custom data and stored in the Terraform state. Keep the state private.

## License

MIT. See [LICENSE](LICENSE).

## Author

Adrian Johnson · [github.com/adrian207](https://github.com/adrian207)
