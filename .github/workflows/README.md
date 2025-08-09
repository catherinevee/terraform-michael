# GitHub Actions Workflows

This directory contains comprehensive GitHub Actions workflows for the Terraform infrastructure project, implementing security best practices, cost optimization, and automated infrastructure management.

## Workflow Overview

### [terraform-validate.yml](./terraform-validate.yml)
**Purpose**: Validates Terraform configurations across all environments
- **Triggers**: Push/PR to main/develop branches, manual dispatch
- **Security**: OIDC authentication, minimal permissions, input validation
- **Features**: 
  - Parallel validation across all environments
  - Security scanning with Trivy and Checkov
  - Infrastructure diagram generation
  - Comprehensive error handling

### [terraform-deploy.yml](./terraform-deploy.yml)
**Purpose**: Secure deployment of infrastructure changes
- **Triggers**: Manual dispatch only (security requirement)
- **Security**: Environment protection, approval gates, OIDC authentication
- **Features**:
  - Environment-specific deployment controls
  - Production requires manual approval
  - Pre and post-deployment validation
  - Destructive change warnings

### [cost-optimization.yml](./cost-optimization.yml)
**Purpose**: Automated cost analysis and optimization recommendations
- **Triggers**: Weekly schedule, manual dispatch
- **Security**: OIDC authentication, read-only AWS permissions
- **Features**:
  - EC2, RDS, and S3 cost analysis
  - Budget variance tracking
  - Optimization recommendations
  - Cost alert notifications

### [security-scan.yml](./security-scan.yml)
**Purpose**: Comprehensive security scanning and compliance checks
- **Triggers**: Push/PR, daily schedule
- **Security**: Multiple scanning tools, SARIF integration
- **Features**:
  - SAST scanning with CodeQL
  - Dependency vulnerability scanning
  - Terraform security analysis
  - Secrets detection
  - Compliance checks

### [diagram-generation.yml](./diagram-generation.yml)
**Purpose**: Automated infrastructure diagram generation
- **Triggers**: Push/PR, manual dispatch
- **Security**: OIDC authentication, minimal permissions
- **Features**:
  - SVG, PNG, and interactive diagrams
  - HTML index generation
  - Environment-specific diagrams
  - Blast-radius integration

## Security Features

### Authentication & Authorization
- **OIDC (OpenID Connect)**: All workflows use OIDC for AWS authentication
- **Minimal Permissions**: Each workflow has only necessary permissions
- **Environment Protection**: Production deployments require approval
- **Input Validation**: All user inputs are validated and sanitized

### Security Scanning
- **SAST**: Static Application Security Testing with CodeQL
- **Dependency Scanning**: Safety, Bandit, Semgrep for Python dependencies
- **Infrastructure Security**: Checkov, TFLint, tfsec for Terraform
- **Container Security**: Trivy and Hadolint for container images
- **Secrets Detection**: TruffleHog and GitLeaks for credential scanning

### Compliance & Governance
- **Policy Enforcement**: Automated compliance checks
- **Audit Trail**: Comprehensive logging and artifact retention
- **Branch Protection**: Required status checks for main branch
- **Environment Controls**: Separate approval processes for sensitive environments

## Performance Optimizations

### Caching Strategy
- **Terraform Modules**: Cached using actions/cache@v4
- **Python Dependencies**: Pip cache for faster installations
- **Cross-OS Sharing**: Cache keys optimized for multi-platform builds

### Parallelization
- **Matrix Strategy**: Parallel execution across environments
- **Job Dependencies**: Optimized dependency chains
- **Concurrency Controls**: Prevents duplicate runs

### Artifact Management
- **Retention Policies**: Environment-specific retention periods
- **Compression**: Large artifacts are compressed
- **Selective Upload**: Only necessary artifacts are uploaded

## Usage Instructions

### Manual Workflow Execution

#### Deploy Infrastructure
```bash
# Navigate to Actions tab in GitHub
# Select "Terraform Deploy" workflow
# Click "Run workflow"
# Configure:
#   - Environment: us-west-1/prod
#   - Action: apply
#   - Auto-approve: false (for production)
```

#### Generate Diagrams
```bash
# Navigate to Actions tab in GitHub
# Select "Infrastructure Diagram Generation" workflow
# Click "Run workflow"
# Configure:
#   - Environment: all
#   - Diagram Type: svg
```

#### Cost Analysis
```bash
# Navigate to Actions tab in GitHub
# Select "Cost Optimization Analysis" workflow
# Click "Run workflow"
# Configure:
#   - Environment: all
#   - Detailed Analysis: true
```

### Environment Configuration

#### Required Secrets
```yaml
AWS_ROLE_ARN: "arn:aws:iam::ACCOUNT:role/GitHubActionsRole"
```

#### Environment Protection Rules
- **Production**: Requires approval from authorized reviewers
- **Staging**: Requires approval for destructive changes
- **Development**: Auto-approval enabled for non-destructive changes

### Branch Protection
```yaml
# Required status checks for main branch:
- terraform-validate
- security-scan
- cost-optimization (if applicable)
```

## Monitoring & Observability

### Metrics Collection
- **DORA Metrics**: Deployment frequency, lead time, MTTR
- **Cost Metrics**: Monthly spend, budget variance, optimization opportunities
- **Security Metrics**: Vulnerability counts, compliance status

### Notifications
- **Success Notifications**: Deployment completion, diagram generation
- **Failure Alerts**: Security issues, deployment failures, cost overruns
- **Warning Notifications**: Non-critical issues, optimization recommendations

### Reporting
- **Security Reports**: SARIF format for GitHub Security tab
- **Cost Reports**: JSON format with detailed breakdowns
- **Infrastructure Diagrams**: SVG/PNG with interactive options

## Best Practices

### Development Workflow
1. **Branch Strategy**: Feature branches → develop → main
2. **Validation**: All changes validated before merge
3. **Security**: Security scans required for all PRs
4. **Documentation**: Infrastructure changes documented

### Deployment Strategy
1. **Environment Promotion**: dev → staging → production
2. **Rollback Plan**: Automated rollback capabilities
3. **Blue-Green**: Zero-downtime deployments
4. **Monitoring**: Post-deployment validation

### Cost Management
1. **Budget Tracking**: Automated budget monitoring
2. **Optimization**: Regular cost optimization recommendations
3. **Alerting**: Cost overrun notifications
4. **Reporting**: Monthly cost reports

## Troubleshooting

### Common Issues

#### Authentication Failures
```bash
# Check OIDC configuration
aws sts assume-role-with-web-identity \
  --role-arn $AWS_ROLE_ARN \
  --web-identity-token $GITHUB_TOKEN
```

#### Terraform Plan Failures
```bash
# Check Terraform configuration
terraform validate
terraform fmt -check
```

#### Security Scan Failures
```bash
# Review security findings
# Address critical vulnerabilities
# Update dependencies if needed
```

### Debug Mode
Enable debug logging by setting the secret:
```yaml
ACTIONS_STEP_DEBUG: true
```

## Compliance & Standards

### Standards Compliance
- **SOC2**: Security controls and monitoring
- **PCI-DSS**: Payment card industry compliance
- **ISO 27001**: Information security management
- **AWS Well-Architected**: Best practices framework

### Audit Requirements
- **365-day Log Retention**: Production environment logs
- **Change Tracking**: All infrastructure changes logged
- **Access Control**: Role-based access with least privilege
- **Incident Response**: Automated alerting and response procedures

## Contributing

### Workflow Development
1. **Security First**: All workflows must follow security best practices
2. **Testing**: Test workflows in development environment first
3. **Documentation**: Update this README for any changes
4. **Review**: Security review required for workflow changes

### Adding New Workflows
1. **Template**: Use existing workflows as templates
2. **Permissions**: Follow principle of least privilege
3. **Security**: Include security scanning and validation
4. **Documentation**: Add comprehensive documentation

## References

### Documentation
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [AWS OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform Security](https://www.terraform.io/docs/cloud/guides/security.html)
- [Blast Radius](https://github.com/28mm/blast-radius)

### Tools
- [Checkov](https://www.checkov.io/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [CodeQL](https://codeql.github.com/)
- [TFLint](https://github.com/terraform-linters/tflint)

### Support
- **Security Issues**: Create security advisory in GitHub
- **Workflow Issues**: Check workflow logs and artifacts
- **Infrastructure Issues**: Review Terraform plan outputs
- **Cost Issues**: Review cost optimization reports 