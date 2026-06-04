# CLAUDE.md

Ground rules for Claude Code (claude.ai/code) when working in this repository.

See [AGENTS.md](AGENTS.md) for vendor-neutral AI ground rules.
See [README.md](README.md) for project overview, modules, conventions, and workflows.

## Claude Code Conventions

### File References

Use markdown link syntax for clickable file references in responses:

- File: `[main.tf](talos-cluster/main.tf)`
- Line: `[variables.tf:42](cloudflared/variables.tf#L42)`
- Range: `[outputs.tf:10-25](gitops/outputs.tf#L10-L25)`
- Directory: `[talos-cluster/](talos-cluster/)`

### Tool Preferences

- **Read** before **Edit/Write**: Required for existing files
- **TodoWrite**: Track multi-step workflows
- **Glob/Grep**: Prefer over shell `find`/`grep`
- **Task** (`subagent_type=Explore`): Open-ended exploration spanning multiple queries
- **Bash**: Reserve for shell-only operations (terraform commands, git, validation)
