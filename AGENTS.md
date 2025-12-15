# AGENTS.md - AI Assistant Guidance for Terraform Modules Repository

This document provides guidance to AI assistants (Claude Code, GitHub Copilot, Cursor, etc.)
when working with this Terraform modules repository.
This is the **primary reference** designed to prevent vendor lock-in.

## Documentation Philosophy

**CRITICAL**: Avoid duplication between documentation files:

- **README.md**: Human-readable project overview, quick start, and module usage
- **AGENTS.md** (this file): AI-specific workflows, mandatory rules, and automation guidance
- **CLAUDE.md**: Claude Code-specific tool integration (references AGENTS.md)

**Guideline**: When content is suitable for human users, place it in README.md and reference it from AGENTS.md. Do not duplicate.

## Repository Overview

See [README.md](README.md) for:

- Complete project overview and available modules
- Module usage examples and quick start guide
- Repository structure details
- Contributing guidelines

**Key Technologies**: Terraform (infrastructure as code), Talos Linux (Kubernetes OS), Flux CD (GitOps), Cloudflare (edge services), Tailscale (mesh networking)

## AI Assistant Principles

### Infrastructure as Code (IaC) Fundamentals

- **Declarative Configuration**: All infrastructure defined in version-controlled code
- **Immutable Infrastructure**: Prefer replacement over modification
- **Idempotency**: Operations can be safely repeated without side effects
- **Module Reusability**: Design modules for reuse across environments and repositories
- **Security by Default**: Secrets management, least privilege, encryption at rest/transit

### AI Development Approach

- **Evidence-Based Decisions**: Reference documentation and research before suggesting changes
- **Documentation First**: Update module README and examples before implementation
- **Test Before Apply**: Validate module changes with `terraform validate` and `terraform plan`
- **Security-First Mindset**: Never compromise on security fundamentals
- **Continuous Validation**: Use automated checks throughout development

## AI Assistant Mandatory Rules

**CRITICAL**: These rules must be followed for all module changes:

### Rule 1: Documentation Before Implementation

**Always update documentation BEFORE modifying module code**:

1. **Review Existing**: Check module README for current functionality and inputs/outputs
2. **Update README**: Document new features, inputs, outputs before implementation
3. **Update Examples**: Provide usage examples for new functionality
4. **Implementation**: Only then write Terraform code
5. **Validation**: Verify documentation matches implementation
6. **terraform-docs**: Run `terraform-docs markdown . > README.md` to update auto-generated sections

**Example Workflow**:

```bash
# CORRECT: Documentation first, then code
1. Update talos-cluster/README.md with new feature description
2. Add example usage in README
3. Write/modify talos-cluster/variables.tf, main.tf, outputs.tf
4. Run terraform-docs to update auto-generated sections

# WRONG: Code without documentation
1. Write talos-cluster/main.tf changes  # NO!
```

**Rationale**: Documentation serves as specification, prevents rework, ensures knowledge transfer, and catches design issues before implementation.

### Rule 2: Temporary Scripts Location

**All temporary, experimental, or one-off scripts MUST be written to `/tmp`**:

- Correct: `/tmp/test-module.sh`, `/tmp/debug-output.py`
- Wrong: `scripts/temp.sh`, `test.py`

**Rationale**: Keeps repository clean, prevents accidental commits of experimental code.

### Rule 3: Module Update Validation

Before any PR or commit, verify:

1. **README updated** with any input/output changes
2. **terraform-docs** has been run to update auto-generated docs
3. **Examples updated** if usage patterns changed
4. **terraform fmt** has been applied
5. **terraform validate** passes

**Enforcement**: AI assistants should refuse to write module code without documentation, prompt user to update README first.

### Rule 4: Markdown Lint Compliance

**All Markdown files MUST pass markdown lint validation**:

- **Immediately after creating or editing** any `.md` file, run `markdownlint <file>` to verify compliance
- **Common lint rules**:
  - MD022: Headings must be surrounded by blank lines
  - MD032: Lists must be surrounded by blank lines
  - Consistent header styles and proper list formatting
  - No trailing spaces or unnecessary blank lines
- **Fix all lint errors** immediately after file changes

**Validation Command**:

```bash
# Validate single file
markdownlint README.md

# Validate all markdown files
markdownlint '**/*.md'
```

## Key Workflows and Commands

### Validation Before Changes

**Always validate before suggesting module changes**:

```bash
# Format check
terraform fmt -check -recursive

# Validate syntax (per module)
cd talos-cluster && terraform init && terraform validate
cd cloudflared && terraform init && terraform validate
cd gitops && terraform init && terraform validate

# Generate documentation
terraform-docs markdown . > README.md
```

### Testing Workflows

**Test module changes in dry-run mode**:

```bash
# Initialize and validate module
terraform init
terraform validate

# Plan with example configuration
terraform plan -var-file=examples/basic.tfvars

# Check output changes
terraform output
```

### Git Commit Convention

Follow Conventional Commits format:

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat` (new functionality), `fix` (bug fix), `docs` (documentation), `refactor` (code restructuring), `test` (adding tests), `chore` (maintenance)

**Scopes**: `talos-cluster`, `cloudflared`, `gitops`, `root` (repository-level changes)

**Examples**:

```bash
feat(talos-cluster): add ZFS pool configuration support
fix(cloudflared): correct tunnel config v5 migration
docs(gitops): update FluxInstance configuration examples
chore(root): update gitignore for terraform providers
```

See [README.md - Contributing](README.md#contributing) for branch strategy and PR process.

## Module Development Guidelines

### Module Structure

Each module MUST follow this structure:

```text
module-name/
├── main.tf           # Primary resources
├── variables.tf      # Input variables with descriptions
├── outputs.tf        # Output values
├── versions.tf       # Provider version constraints
├── README.md         # Module documentation
└── templates/        # Optional template files
```

### Variable Conventions

- **Required variables**: No default value
- **Optional variables**: Provide sensible defaults
- **Sensitive variables**: Mark with `sensitive = true`
- **Descriptions**: Always include clear descriptions
- **Type constraints**: Use specific types (`string`, `number`, `bool`, `list`, `map`, `object`)

**Example**:

```hcl
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (e.g., v1.31.0)"
  type        = string
  default     = "v1.31.0"
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key for joining the tailnet"
  type        = string
  sensitive   = true
}
```

### Output Conventions

- **Provide useful outputs**: Include outputs that consumers need
- **Sensitive outputs**: Mark appropriately
- **Descriptions**: Always include descriptions

### AI-Specific Guidance

When suggesting module changes:

1. **Read Context First**: Review module README and existing code before suggesting changes
2. **Follow Conventions**: Adhere to Terraform naming, formatting, and structural guidelines
3. **Validate Before Commit**: Run formatters, linters, and terraform validate
4. **Security First**: Never commit secrets; use sensitive variable marking
5. **Explain Trade-offs**: Discuss pros/cons of different approaches
6. **Reference Documentation**: Link to official Terraform and provider documentation
7. **Version Awareness**: Check compatibility with pinned provider versions
8. **Backward Compatibility**: Consider existing users when making changes
9. **Idempotency**: Ensure all resources are safe to apply repeatedly
10. **Test Before Apply**: Use terraform plan to preview changes

## Available Modules

### talos-cluster

Generates Talos Linux machine configurations for Kubernetes clusters with Tailscale integration.

**Key Features**: Tailscale mesh networking, per-node extensions, SBC overlay support, KubePrism, CNI flexibility, OpenEBS support

### cloudflared

Creates Cloudflare Zero Trust Tunnels with ingress rules and DNS records.

**Key Features**: Terraform-managed tunnel configuration, ingress routing, DNS CNAME records, Cloudflare Provider v5 support

### gitops

Bootstraps Flux CD on Kubernetes clusters using the Flux Operator.

**Key Features**: cert-manager integration, FluxInstance CRD, SOPS age key support, GitHub repository sync

## Quick Reference

### Documentation Locations

- **Project overview and module list**: [README.md](README.md)
- **Module documentation**: `<module>/README.md`
- **Claude Code integration**: [CLAUDE.md](CLAUDE.md)

### Essential Commands

```bash
# Validation
terraform fmt -check -recursive
terraform validate

# Documentation generation
terraform-docs markdown . > README.md

# Testing
terraform init
terraform plan
```

### External Resources

- **Terraform**: <https://www.terraform.io/docs>
- **Terraform Registry**: <https://registry.terraform.io/>
- **Talos Linux**: <https://www.talos.dev/docs>
- **Flux CD**: <https://fluxcd.io/docs>
- **Cloudflare**: <https://developers.cloudflare.com/>
- **Tailscale**: <https://tailscale.com/kb>

## Contributing

See [README.md - Contributing](README.md#contributing) for the contribution workflow and PR process.

## License

See [LICENSE](LICENSE) for licensing information.
