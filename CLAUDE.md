# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this Terraform modules repository.

## Primary Reference

**IMPORTANT**: See [AGENTS.md](AGENTS.md) for the primary, vendor-neutral AI assistant guidance. This document only contains Claude Code-specific extensions.

## Claude Code-Specific Features

### File References

When referencing files or code locations in responses, use markdown link syntax for clickable references:

- Files: `[main.tf](talos-cluster/main.tf)`
- Lines: `[variables.tf:42](cloudflared/variables.tf#L42)`
- Ranges: `[outputs.tf:10-25](gitops/outputs.tf#L10-L25)`
- Directories: `[talos-cluster/](talos-cluster/)`

### Tool Usage Patterns

**Module Analysis**:

1. **Glob** for finding files: `**/*.tf`, `**/README.md`
2. **Grep** for searching patterns: `variable "`, `resource "`, `module "`
3. **Read** for examining configurations
4. **Task** (subagent_type=Explore) for open-ended codebase exploration

**Making Changes**:

1. **Always Read before Edit/Write** - Required for existing files
2. **TodoWrite** - Structure multi-step module changes
3. **Bash** - Validate with `terraform fmt -check`, `terraform validate`
4. **Bash** - Test with `terraform plan`

### Task Management for Modules

Use TodoWrite for complex module operations:

```text
1. Plan phase: Update README with new feature description
2. Implementation: Modify variables.tf, main.tf, outputs.tf
3. Validation: terraform fmt, terraform validate
4. Documentation: Run terraform-docs to update auto-generated sections
5. Testing: terraform plan with example configuration
```

### Workflow Integration

For validation commands and git commit conventions, see [AGENTS.md - Key Workflows and Commands](AGENTS.md#key-workflows-and-commands).

**Claude Code Specific**: Use TodoWrite tool to track multi-step validation workflows.

### Module Development Workflow

| Step | Action | Tool |
|------|--------|------|
| 1 | Read existing module code | Read |
| 2 | Update README documentation | Edit |
| 3 | Modify Terraform files | Edit |
| 4 | Format code | Bash: `terraform fmt` |
| 5 | Validate syntax | Bash: `terraform validate` |
| 6 | Update auto-docs | Bash: `terraform-docs markdown .` |
| 7 | Test changes | Bash: `terraform plan` |

### Quick Reference

For complete documentation on:

- **Validation workflows**: See [AGENTS.md - Validation Before Changes](AGENTS.md#validation-before-changes)
- **Git commit convention**: See [AGENTS.md - Git Commit Convention](AGENTS.md#git-commit-convention)
- **Module structure**: See [AGENTS.md - Module Structure](AGENTS.md#module-structure)
- **Variable conventions**: See [AGENTS.md - Variable Conventions](AGENTS.md#variable-conventions)
- **AI workflows**: See [AGENTS.md - AI-Specific Guidance](AGENTS.md#ai-specific-guidance)

### Additional Context

- **Project overview**: [README.md](README.md)
- **Talos Cluster module**: [talos-cluster/README.md](talos-cluster/README.md)
- **Cloudflared module**: [cloudflared/README.md](cloudflared/README.md)
- **GitOps module**: [gitops/README.md](gitops/README.md)
