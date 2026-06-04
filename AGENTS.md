# AGENTS.md

Ground rules for AI assistants (Claude Code, GitHub Copilot, Cursor, etc.) working in this repository.

This is the **primary reference**, designed to prevent vendor lock-in.

## Documentation Map

- **[README.md](README.md)**: Project overview, modules, conventions, workflows, commands, and external resources
- **AGENTS.md** (this file): AI ground rules — mandatory behavior for all AI assistants
- **[CLAUDE.md](CLAUDE.md)**: Claude Code-specific tool conventions

Avoid duplication: project information lives in README.md; ground rules live here.

## Principles

### Infrastructure as Code

- **Declarative**: All infrastructure defined in version-controlled code
- **Immutable**: Prefer replacement over modification
- **Idempotent**: Operations safely repeatable without side effects
- **Reusable**: Design modules for use across environments
- **Secure by Default**: Secrets management, least privilege, encryption

### AI Development Approach

- **Evidence-Based**: Reference documentation before suggesting changes
- **Documentation First**: Update README and examples before implementation
- **Test Before Apply**: Validate with `terraform validate` and `terraform plan`
- **Security First**: Never compromise on security fundamentals
- **Continuous Validation**: Use automated checks throughout development

## Mandatory Rules

### Rule 1: Documentation Before Implementation

Update documentation BEFORE modifying code:

1. Review the existing module README
2. Document new features, inputs, and outputs
3. Add usage examples
4. Implement Terraform changes
5. Verify docs match implementation
6. Run `terraform-docs markdown . > README.md`

**Rationale**: Documentation serves as specification, prevents rework, ensures knowledge transfer, and catches design issues before implementation.

### Rule 2: Temporary Scripts Go in `/tmp`

All temporary, experimental, or one-off scripts MUST be written to `/tmp`:

- Correct: `/tmp/test-module.sh`, `/tmp/debug-output.py`
- Wrong: `scripts/temp.sh`, `test.py`

**Rationale**: Keeps the repository clean and prevents accidental commits of experimental code.

### Rule 3: Validate Before Commit

Before any PR or commit, verify:

1. README reflects input/output changes
2. `terraform-docs` regenerated
3. Examples updated if usage patterns changed
4. `terraform fmt` applied
5. `terraform validate` passes

See [README — Workflows](README.md#workflows) for the exact commands.

### Rule 4: Markdown Lint Compliance

All Markdown files MUST pass `markdownlint`:

- Run `markdownlint <file>` immediately after editing any `.md` file
- Fix all lint errors before considering the change complete

## AI-Specific Guidance

When suggesting changes:

1. **Read Context First**: Review module README and existing code
2. **Follow Conventions**: Adhere to project conventions (see [README — Module Conventions](README.md#module-conventions))
3. **Validate Before Commit**: Run formatters, linters, and `terraform validate`
4. **Security First**: Never commit secrets; use sensitive variable marking
5. **Explain Trade-offs**: Discuss pros/cons of different approaches
6. **Reference Documentation**: Link to official Terraform and provider docs
7. **Version Awareness**: Check compatibility with pinned provider versions
8. **Backward Compatibility**: Consider existing users when making changes
9. **Idempotency**: Ensure all resources are safe to apply repeatedly
10. **Test Before Apply**: Use `terraform plan` to preview changes
