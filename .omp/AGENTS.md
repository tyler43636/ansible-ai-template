# AGENTS.md

This file provides guidance for agentic coding agents working in this repository.

## Project Overview

Ansible automation template repository. It provides a baseline structure with a development shell and pre-configured tools.

## Repository Structure

```
.
├── ansible.cfg              # Ansible configuration (inventory, roles path, vault, become)
├── flake.nix                # Nix flake defining the dev shell and dependencies
├── requirements.yml         # Required Ansible collections
├── inventory/
│   ├── hosts.yml            # Host definitions
│   └── group_vars/all.yml   # Shared variables for all hosts
├── playbooks/               # Thin wrappers targeting hosts + invoking single roles
├── roles/                   # Ansible roles with standard structure
│   └── <name>/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── templates/
│       ├── files/
│       └── defaults/main.yml
├── molecule/                # Molecule test scaffolding
├── .omp/                    # OMP agent config (skills, agents, rules, MCP)
└── .mcp.json                # Ansible MCP server (fallback; canonical is .omp/mcp.json)
```

## Build/Lint/Test Commands

Run these inside the Nix dev shell (`nix develop`):

```bash
# Install dependencies
ansible-galaxy collection install -r requirements.yml

# Validate Ansible configuration and inventory
ansible-playbook --syntax-check playbooks/*.yml
ansible-inventory --list

# Validate a specific playbook (lint + syntax)
ansible-playbook playbooks/example.yml --syntax-check

# Dry run (check mode) - simulate changes without applying
ansible-playbook playbooks/example.yml --check

# Run against specific host(s)
ansible-playbook playbooks/example.yml --limit localhost

# Target specific hosts with ad-hoc (use MCP tools when possible)
ansible -m ping all --limit localhost

# Lint YAML files
ansible-lint playbooks/example.yml

# Run molecule tests
molecule test
```

## Ansible Best Practices

### YAML Formatting
- Always start YAML files with document marker: `---`
- Use 2-space indentation (Ansible convention)
- Use sentence case for task names: `name: Update apt cache`
- Use `yes`/`no` for boolean values in most Ansible modules (not `true`/`false`)

### Task Naming
- Use descriptive, sentence-case task names
- Prefix with action: `name: Ensure package is installed` not `name: install package`

### Variable Naming
- Use snake_case: `apt_upgrade`, `timer_name`, `script_args`
- Default variables in `roles/<name>/defaults/main.yml`
- Group variables in `inventory/group_vars/all.yml`
- Avoid shadowing Ansible builtin variables

### Role Structure
- Each role is self-contained with tasks, handlers, templates, files, defaults
- Playbooks are thin wrappers: only `hosts`, `become`, and `roles` keys
- Handler-based changes (restart services) go in handlers, not tasks

### Idempotency
- All tasks must be idempotent - safe to run multiple times
- Use `changed_when`, `check_mode` appropriately
- Prefer `apt: name=package state=present` over shell commands

### Error Handling
- Use `failed_when` to specify what constitutes failure
- Use `ignore_errors: yes` sparingly and with comment explaining why
- Use `changed_when: false` when task should never report changes
- Shell scripts: use `set -euo pipefail` for strict error handling

## Shell Script Guidelines

Scripts in `roles/<name>/files/` should:
- Start with `#!/usr/bin/env bash`
- Use `set -euo pipefail` for strict error handling
- Use `[[ ]]` for conditional tests (not `[ ]`)
- Prefer `$(command)` over backticks
- Use `mapfile` or `read -a` for array input
- Exit with explicit `exit 0` or `exit 1`

## Jinja2 Template Guidelines

- Variable interpolation: `{{ variable_name }}`
- Filter usage: `{{ value | default('fallback') }}`
- Loop syntax: `{% for item in items %}{% endfor %}`
- Conditional: `{% if condition %}...{% endif %}`
- Whitespace control: `{%- if condition -%}` or `{{- value -}}`
- Always quote strings: `"{{ var }}"` unless var is definitely numeric/boolean

## Inventory

- Default hosts defined in `inventory/hosts.yml`
- Shared vars in `inventory/group_vars/all.yml`
- Vault-encrypted secrets in group_vars; password file at `.vault_pass` (gitignored)

## MCP Server

This project has an Ansible MCP server configured in `.omp/mcp.json`. Use the `mcp__ansible__*` tools when available:
- `mcp__ansible__ping` - ping hosts
- `mcp__ansible__run_playbook` - run playbooks
- `mcp__ansible__validate_playbook` - syntax check
- `mcp__ansible__inventory` - list inventory

## Agent Skills

Five project skills are available via `skill://`:
- `skill://ansible` — Ansible role/playbook authoring, lint, and verification
- `skill://molecule` — Molecule test scenario authoring and debugging
- `skill://vault` — Ansible Vault encrypted secrets handling
- `skill://nix-dev-shell` — Modifying the Nix development environment (`flake.nix`)
- `skill://jinja2-templating` — Jinja2 template authoring rules and safety

## Prohibited Patterns

- Never commit secrets, keys, or credentials to the repository
- Never use `gather_facts: yes` unless specifically needed (slow)
- Avoid `shell:` module when `command:` suffices
- Avoid `raw:` module unless necessary (no idempotency)
- Do not modify `ansible.cfg` settings that break the project conventions