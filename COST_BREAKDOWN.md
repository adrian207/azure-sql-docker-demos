# Azure SQL Docker Demos - Cost Breakdown

> **Region:** West US 2  
> **Currency:** USD  
> **Pricing Date:** October 2025  
> **Note:** Prices are estimates and may vary. Always check [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for current rates.

---

## 💰 Monthly Cost Estimate

### Standard Configuration (Pay-As-You-Go)

| Resource | Specification | Quantity | Hours/Month | Rate (USD/hr) | Monthly Cost |
|----------|--------------|----------|-------------|---------------|--------------|
| **Rocky Linux VM** | Standard_D8s_v3 (8 vCPU, 32 GB RAM) | 1 | 730 | $0.384 | **$280.32** |
| **Windows Server VM** | Standard_D4s_v3 (4 vCPU, 16 GB RAM) | 1 | 730 | $0.296 | **$216.08** |
| **Managed Disk (Linux)** | Premium SSD P30 (1 TB) | 1 | - | - | **$122.88** |
| **Managed Disk (Windows)** | Premium SSD P20 (512 GB) | 1 | - | - | **$73.73** |
| **Public IP (Static)** | Standard | 1 | 730 | $0.005 | **$3.65** |
| **Bandwidth (Egress)** | Data Transfer Out (5 GB est.) | - | - | $0.087/GB | **$0.44** |
| **Network Security Group** | - | 2 | - | - | **$0.00** |
| **Virtual Network** | - | 1 | - | - | **$0.00** |

### **Total Monthly Cost: ~$696.10 USD**

---

## 💡 Cost Optimization Options

### Option 1: Development/Testing Hours Only
**Run VMs only when needed (8 hours/day, 20 days/month = 160 hours)**

| Resource | Monthly Cost |
|----------|--------------|
| Rocky Linux VM | **$61.44** |
| Windows Server VM | **$47.36** |
| Managed Disks | **$196.61** (always charged) |
| Networking | **$4.09** |
| **TOTAL** | **~$309.50/month** |

**Savings: ~56%** by stopping VMs when not in use.

---

### Option 2: Smaller VM Sizes (Testing Only)

| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| Rocky Linux VM | Standard_D4s_v3 (4 vCPU, 16 GB) | **$140.16** |
| Windows Server VM | Standard_D2s_v3 (2 vCPU, 8 GB) | **$108.04** |
| Managed Disks | Standard SSD (E20 256GB each) | **$38.40** |
| Networking | Same as above | **$4.09** |
| **TOTAL** | | **~$290.69/month** |

**Savings: ~58%** but reduced performance for demos.

---

### Option 3: Azure Reserved Instances (1-Year Commitment)

| Resource | Pay-As-You-Go | 1-Year Reserved | Savings |
|----------|---------------|-----------------|---------|
| Rocky Linux VM (D8s_v3) | $280.32 | **$192.23** | 31% |
| Windows Server VM (D4s_v3) | $216.08 | **$153.76** | 29% |
| **Monthly Total** | $496.40 | **$345.99** | **30%** |

*Requires upfront or monthly commitment for 1 or 3 years*

---

### Option 4: Azure Hybrid Benefit (Windows)

If you have existing Windows Server licenses with Software Assurance:

| Resource | Standard Cost | With Hybrid Benefit | Savings |
|----------|--------------|---------------------|---------|
| Windows Server VM (D4s_v3) | $216.08 | **~$96.36** | ~55% |

**Total with Hybrid Benefit: ~$576.78/month** (saves ~$120/month)

---

## 🆓 Free Components

The following components have **zero additional cost**:

- ✅ **SQL Server Developer Edition** - Free (not for production)
- ✅ **Rocky Linux 9** - Free (no license fees)
- ✅ **Docker/Podman** - Free and open source
- ✅ **Apache Guacamole** - Free and open source
- ✅ **Prometheus** - Free and open source
- ✅ **Grafana** - Free and open source
- ✅ **SQL Server on Linux containers** - Free (Developer Edition)

---

## 📊 Cost by Scenario

### Branch 1: feat/sql-log-shipping
**2x SQL Server containers + Monitoring**
- Same infrastructure cost as above
- **Estimated: $696.10/month**

### Branch 2: feat/sql-transactional-replication
**2x SQL Server containers + Monitoring**
- Same infrastructure cost as above
- **Estimated: $696.10/month**

### Branch 3: feat/sql-always-on-ag
**3x SQL Server containers + Monitoring**
- Recommended: Upgrade Linux VM to Standard_D16s_v3 (16 vCPU, 64 GB)
- Additional cost: ~$280/month more
- **Estimated: $976.10/month**

---

## ⚠️ Additional Costs to Consider

### 1. **SQL Server Licensing (Production Use)**
If you need to use this in production with Enterprise Edition:
- **SQL Server Enterprise (per core/hour):** ~$0.45/hour per vCPU
- **D8s_v3 (8 vCPU) = $2,628/month** just for SQL licensing
- **Recommendation:** Use Developer Edition for demos only

### 2. **Data Transfer Costs**
- **Inbound:** Free
- **Outbound (first 5 GB/month):** Free
- **Outbound (5+ GB):** $0.087/GB in West US 2
- **Estimated for demos:** $5-10/month

### 3. **Azure Monitor / Log Analytics (Optional)**
- **Data ingestion:** $2.30/GB
- **Data retention (90 days):** Free
- **Estimated:** $10-20/month if enabled

### 4. **Backup Storage (Optional)**
If you enable Azure Backup:
- **LRS Storage:** $0.10/GB/month
- **Estimated for 100 GB:** $10/month

---

## 🎯 Recommended Setup by Use Case

### For Learning & Demos (Recommended)
```
Configuration: Standard VMs + Developer Edition
Cost: $696/month (or $309/month with stop/start)
Best for: Personal learning, demos, proof-of-concepts
```

### For Development Team
```
Configuration: Standard VMs + Reserved Instances + Hybrid Benefit
Cost: $456/month
Best for: Team development, testing, CI/CD integration
```

### For Production Workloads
```
⚠️ This architecture is NOT recommended for production
Consider: Azure SQL Database Managed Instance or Production-grade VMs
Estimated Cost: $2,000-5,000+/month depending on requirements
```

---

## 💵 Cost Control Best Practices

1. **Auto-shutdown schedules** - Use Azure DevTest Labs or automation
2. **Right-size VMs** - Start small, scale up only if needed
3. **Use Azure Spot VMs** - Up to 90% savings (can be evicted)
4. **Monitor usage** - Set up budget alerts in Azure Cost Management
5. **Delete when not needed** - Spin up for demos, tear down after
6. **Use terraform destroy** - Clean up all resources to avoid charges

---

## 📈 Cost Calculation Tool

Use the official Azure Pricing Calculator:
👉 https://azure.microsoft.com/en-us/pricing/calculator/

**Pre-configured estimate for this project:**
- Add 1x D8s_v3 Linux VM (West US 2, 730 hours)
- Add 1x D4s_v3 Windows VM (West US 2, 730 hours)
- Add 2x Premium SSD Managed Disks
- Add 1x Standard Public IP

---

## ❓ FAQ

**Q: Can I run this for free?**
A: No, Azure charges for compute and storage. Minimum ~$300/month with optimization.

**Q: What about Azure Free Tier?**
A: Free tier includes limited resources, but not enough for this multi-VM setup.

**Q: Is there a cheaper alternative?**
A: Yes - use local Docker Desktop or nested virtualization on a single local machine.

**Q: Can I use Spot VMs?**
A: Yes! Can reduce compute costs by 70-90%, but VMs can be evicted with 30-second notice. Good for non-critical demos.

**Q: What's the cheapest way to test this?**
A: Deploy only when needed, use smaller VMs (D2s_v3/D4s_v3), use Standard SSDs instead of Premium, and destroy resources immediately after demos.

---

## 📞 Support

For questions about Azure pricing:
- Azure Support: https://azure.microsoft.com/en-us/support/
- Azure Pricing: https://azure.microsoft.com/en-us/pricing/

Last Updated: October 2025

