# Contributing to Azure SQL Docker Demos

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

Be respectful, professional, and constructive in all interactions.

## How to Contribute

### Reporting Issues

1. Check existing issues first
2. Provide clear title and description
3. Include steps to reproduce (for bugs)
4. Include Terraform version, Azure region, and error messages

### Suggesting Features

1. Check existing feature requests
2. Explain the use case and benefits
3. Consider cost implications
4. Provide examples if possible

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Add comments where needed
   - Update documentation

4. **Test your changes**
   ```bash
   # Format Terraform code
   terraform fmt -recursive
   
   # Validate configuration
   terraform validate
   
   # Deploy and test
   terraform apply
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add Always On AG configuration"
   ```

6. **Push and create PR**
   ```bash
   git push origin feat/your-feature-name
   ```

## Development Guidelines

### Terraform Code Style

```hcl
# Use descriptive resource names
resource "azurerm_linux_virtual_machine" "sql_host" {
  name = "${var.project_name}-sql-host"
  # ...
}

# Add comments for complex logic
# This configures the data disk with read-only caching for SQL performance
caching = "ReadOnly"

# Use variables for flexibility
variable "vm_size" {
  description = "Azure VM size for SQL containers"
  type        = string
  default     = "Standard_D8s_v3"
}
```

### Documentation

- Update README.md for major changes
- Add comments in code for complex configurations
- Include cost implications
- Provide examples

### Cost Awareness

Every change should consider:
- Azure resource costs
- Cost optimization opportunities
- Auto-shutdown capabilities
- Alternative cheaper options

### Security

- Never commit secrets or passwords
- Use Terraform `sensitive = true` for credentials
- Follow least-privilege principles
- Document security implications

## Branch Strategy

- `main` - Stable, production-ready code
- `feat/*` - Feature branches
  - `feat/sql-log-shipping`
  - `feat/sql-transactional-replication`
  - `feat/sql-always-on-ag`
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates

## Testing Checklist

Before submitting PR:

- [ ] `terraform fmt` - Code formatted
- [ ] `terraform validate` - No syntax errors
- [ ] `terraform plan` - Reviewed changes
- [ ] `terraform apply` - Successfully deployed
- [ ] Manual testing - All services work
- [ ] Documentation - Updated if needed
- [ ] Cost analysis - Documented cost impact

## Commit Message Format

```
<type>: <short summary>

<optional longer description>

<optional footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Testing
- `chore:` - Maintenance

**Examples:**
```
feat: add Grafana dashboard for SQL monitoring

Adds pre-configured Grafana dashboard showing:
- SQL Server performance metrics
- Container resource usage
- Replication lag monitoring

Cost impact: None (Grafana already deployed)
```

## Questions?

- Open an issue for questions
- Tag with `question` label
- Check existing discussions first
- Email: [adrian207@gmail.com](mailto:adrian207@gmail.com)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 👤 Project Maintainer

**Adrian Johnson**
- Email: [adrian207@gmail.com](mailto:adrian207@gmail.com)
- GitHub: [@adrian207](https://github.com/adrian207)

Thank you for contributing! 🎉

