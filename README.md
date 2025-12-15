# Terraform Modules

> Reusable Terraform modules for hybrid cloud Kubernetes infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Talos](https://img.shields.io/badge/Talos-1.8+-FF6600?logo=linux)](https://www.talos.dev/)
[![Flux CD](https://img.shields.io/badge/Flux_CD-v2.7+-5468FF?logo=flux)](https://fluxcd.io/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-v5-F38020?logo=cloudflare)](https://www.cloudflare.com/)

## Overview

This repository contains reusable Terraform modules for deploying and managing hybrid cloud Kubernetes infrastructure.
These modules are designed to be used as Git submodules across multiple infrastructure repositories.

### Design Goals

- **Reusability**: Modules designed for use across multiple environments and repositories
- **Modularity**: Each module handles a specific infrastructure component
- **Documentation**: Comprehensive README with inputs, outputs, and examples
- **Security by Default**: Sensitive variables marked appropriately, secure defaults
- **Versioned**: Use Git tags for stable module versions

## Available Modules

### talos-cluster

Generates Talos Linux machine configurations for Kubernetes clusters with Tailscale integration.

**Features**:

- Tailscale mesh network integration
- Per-node Talos system extensions via Image Factory
- SBC overlay support (Raspberry Pi, Rock Pi, etc.)
- KubePrism for high-availability API access
- CNI flexibility (Flannel, Cilium, Calico)
- OpenEBS storage support (LocalPV, Mayastor, ZFS)

**Usage**:

```hcl
module "talos_cluster" {
  source = "git::https://github.com/shangkuei/terraform-modules.git//talos-cluster?ref=v1.0.0"

  cluster_name = "my-cluster"

  control_plane_nodes = {
    cp-01 = {
      tailscale_ipv4 = "100.64.0.10"
      install_disk   = "/dev/sda"
      hostname       = "cp-01"
    }
  }

  worker_nodes = {
    worker-01 = {
      tailscale_ipv4 = "100.64.0.20"
      install_disk   = "/dev/sda"
      hostname       = "worker-01"
    }
  }

  tailscale_tailnet  = "example-org"
  tailscale_auth_key = var.tailscale_auth_key
}
```

See [talos-cluster/README.md](talos-cluster/README.md) for complete documentation.

### cloudflared

Creates Cloudflare Zero Trust Tunnels with ingress rules and DNS records.

**Features**:

- Terraform-managed tunnel configuration (Cloudflare Provider v5)
- Ingress rules for hostname-to-service routing
- Optional DNS CNAME record creation
- Tunnel token output for cloudflared deployment

**Usage**:

```hcl
module "tunnel" {
  source = "git::https://github.com/shangkuei/terraform-modules.git//cloudflared?ref=v1.0.0"

  account_id  = var.cloudflare_account_id
  tunnel_name = "my-tunnel"

  ingress_rules = [
    {
      hostname = "app.example.com"
      service  = "http://app.default.svc.cluster.local:8080"
    }
  ]

  zone_id = var.cloudflare_zone_id
  dns_records = {
    "app" = { name = "app" }
  }
}
```

See [cloudflared/README.md](cloudflared/README.md) for complete documentation.

### gitops

Bootstraps Flux CD on Kubernetes clusters using the Flux Operator.

**Features**:

- cert-manager integration for webhook certificates
- Flux Operator with FluxInstance CRD
- SOPS age key integration for encrypted manifests
- GitHub repository synchronization

**Usage**:

```hcl
module "gitops" {
  source = "git::https://github.com/shangkuei/terraform-modules.git//gitops?ref=v1.0.0"

  cluster_name = "my-cluster"
  cluster_path = "./kubernetes/clusters/my-cluster"

  github_owner      = "my-org"
  github_repository = "infrastructure"
  github_token      = var.github_token

  sops_age_key = file("~/.config/sops/age/flux.txt")
}
```

See [gitops/README.md](gitops/README.md) for complete documentation.

## Quick Start

### Using as Git Submodule

```bash
# Add as submodule to your infrastructure repository
git submodule add https://github.com/shangkuei/terraform-modules.git terraform/modules

# Initialize submodules
git submodule update --init --recursive

# Update to latest
git submodule update --remote
```

### Using with Git Source

```hcl
module "example" {
  # Pin to specific version tag
  source = "git::https://github.com/shangkuei/terraform-modules.git//module-name?ref=v1.0.0"

  # Or use branch (for development)
  source = "git::https://github.com/shangkuei/terraform-modules.git//module-name?ref=main"
}
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/shangkuei/terraform-modules.git
cd terraform-modules

# Initialize a module
cd talos-cluster
terraform init

# Validate
terraform validate

# Format
terraform fmt -recursive
```

## Repository Structure

```text
terraform-modules/
├── talos-cluster/           # Talos Linux cluster configuration module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── templates/
│   └── README.md
│
├── cloudflared/             # Cloudflare Tunnel module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── gitops/                  # Flux CD GitOps bootstrap module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── README.md
│
├── AGENTS.md               # AI assistant guidance
├── CLAUDE.md               # Claude Code specific guidance
└── README.md               # This file
```

## Requirements

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.5.0 | Infrastructure as Code |
| terraform-docs | >= 0.16.0 | Documentation generation |
| markdownlint | >= 0.32.0 | Markdown validation |

## Development

### Adding a New Module

1. Create module directory with standard structure:

   ```bash
   mkdir new-module
   cd new-module
   touch main.tf variables.tf outputs.tf versions.tf README.md
   ```

2. Write initial README with module description and planned inputs/outputs

3. Implement the module following conventions in [AGENTS.md](AGENTS.md)

4. Generate documentation:

   ```bash
   terraform-docs markdown . >> README.md
   ```

5. Validate:

   ```bash
   terraform fmt -recursive
   terraform init
   terraform validate
   markdownlint README.md
   ```

### Updating Existing Modules

1. Update README documentation first
2. Make code changes
3. Run `terraform-docs markdown .` to update auto-generated sections
4. Validate and test changes
5. Create version tag if releasing

## Versioning

This repository uses semantic versioning for module releases:

- **Major**: Breaking changes to module interfaces
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, documentation updates

Use Git tags for stable references:

```bash
# Create a new version tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## Contributing

1. **Read the guides**:
   - [AGENTS.md](AGENTS.md): AI assistant guidance (vendor-neutral)
   - [CLAUDE.md](CLAUDE.md): Claude Code specific guidance

2. **Create a feature branch**:

   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make changes**:
   - Update README documentation first
   - Follow Terraform conventions
   - Run validation checks

4. **Validate locally**:

   ```bash
   terraform fmt -recursive
   terraform validate
   markdownlint '**/*.md'
   ```

5. **Create pull request**:

   ```bash
   git push origin feature/my-feature
   gh pr create --title "feat(module): description" --body "Details"
   ```

## Related Projects

- [infrastructure](https://github.com/shangkuei/infrastructure): Main infrastructure repository using these modules

## License

See [LICENSE](LICENSE) for licensing information.

## Acknowledgments

Built with:

- [Terraform](https://www.terraform.io/) by HashiCorp
- [Talos Linux](https://www.talos.dev/) by Sidero Labs
- [Flux CD](https://fluxcd.io/) by CNCF
- [Cloudflare](https://www.cloudflare.com/)
- [Tailscale](https://tailscale.com/)
