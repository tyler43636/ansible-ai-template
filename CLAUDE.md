# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible automation template for managing servers. Includes a generic example role, molecule tests, and an integrated development environment via Nix.

## Common Commands

```bash
# Enter the development shell (or use direnv)
nix develop

# Install required collections
ansible-galaxy collection install -r requirements.yml

# Run a playbook
ansible-playbook playbooks/example.yml

# Run a playbook with extra variables
ansible-playbook playbooks/example.yml -e "var_name=value"

# Target specific hosts
ansible-playbook playbooks/example.yml --limit example_host

# Dry run
ansible-playbook playbooks/example.yml --check

# Validate syntax
ansible-playbook playbooks/example.yml --syntax-check

# Run molecule tests
molecule test
```

## Architecture

**Inventory:** Hosts are defined in `inventory/hosts.yml`. Shared variables in `inventory/group_vars/all.yml`.

**Roles pattern:** Each role lives in `roles/<name>/` with standard Ansible structure (tasks, templates, handlers, files, defaults). Playbooks in `playbooks/` are thin wrappers that target a host group and invoke a single role or related set of roles.

**ansible.cfg:** Inventory path and roles path are set so commands work from the repo root without flags. `host_key_checking` is disabled, `become` is enabled by default, and retry files are off.

**Vault:** Sensitive values use `ansible-vault encrypt_string`. The vault password file is `.vault_pass` (gitignored). Encrypt new secrets with:
```bash
ansible-vault encrypt_string 'SECRET' --name 'var_name'
```

## Ansible Conventions

- Start YAML files with `---`
- Use 2-space indentation
- Use sentence-case task names: `name: Update apt cache`
- Use `yes`/`no` for boolean values in Ansible modules
- Use snake_case for variables
- Default variables go in `roles/<name>/defaults/main.yml`
- Playbooks are thin wrappers: only `hosts`, `become`, and `roles` keys
- Handler-based restarts go in `handlers/main.yml`, not inline in tasks
- All tasks must be idempotent; prefer native modules (`apt`, `copy`, `template`) over `shell`/`command`
- Use FQCN for modules (e.g., `ansible.builtin.apt` not just `apt`)

## MCP Server

This project has an Ansible MCP server configured in `.mcp.json`. Use the `mcp__ansible__*` tools for operations like pinging hosts, running ad-hoc tasks, validating playbooks, and managing inventory -- prefer these over raw `ansible-playbook` bash commands when available.
(Note: You may need to have `ansible-mcp-server` installed via npm if you plan to use this integration.)

## Dependencies

Required Ansible collections are listed in `requirements.yml`.
