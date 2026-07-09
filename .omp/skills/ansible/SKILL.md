---
name: ansible
description: Develop, lint, and troubleshoot Ansible playbooks, roles, collections, inventories, and execution environments.
---

# Ansible Development

Use this skill when editing Ansible YAML, roles, collections, inventories, molecule scenarios, or ansible-lint configuration.

## First Steps

1. Inspect the target project layout before editing: playbooks, `roles/`, `collections/`, `group_vars/`, `host_vars/`, `inventory`, `ansible.cfg`, and lint config when present.
2. Prefer the project's existing role structure, variable naming, tag style, and collection dependencies.
3. Do not set `ANSIBLE_CONFIG` or `ANSIBLE_INVENTORY` globally for a repo unless the project already does; Ansible resolves both from the working directory.
4. Verify with the narrowest command that covers the change.

## Editing Rules

- Keep tasks idempotent: use purpose-built modules instead of `shell`/`command` when a module exists.
- Use `changed_when` and `failed_when` for commands whose change or failure semantics differ from exit status.
- Put reusable values in `defaults/main.yml`; put environment-specific values in inventory/group vars.
- Use fully qualified collection names when the project already does, or when ambiguity is possible.
- Keep handlers for service restarts/reloads; notify them from tasks instead of restarting inline.
- Do not check in secrets. The vault password file is `.vault_pass` (gitignored). Encrypt new secrets with `ansible-vault encrypt_string 'SECRET' --name 'var_name'`; reference encrypted values as normal variables in playbooks.

## MCP Server

This project configures an Ansible MCP server in `.mcp.json`. Prefer `mcp__ansible__*` tools over raw `ansible-playbook` bash calls when available:

- `mcp__ansible__ping` — ping hosts to confirm connectivity
- `mcp__ansible__run_playbook` — run a playbook against the configured inventory
- `mcp__ansible__validate_playbook` — syntax-check without running
- `mcp__ansible__inventory` — list inventory hosts and variables

Fall back to `ansible-playbook` CLI only when the MCP server is unavailable or the required operation is not covered by the four tools above.

## Molecule

Molecule scenarios live under `molecule/<scenario>/`. The default scenario has three files:

- `molecule.yml` — driver, platform image, provisioner, verifier config. The platform image is the only field that changes when switching distros (e.g. `geerlingguy/docker-ubuntu2404-ansible:latest`); all other keys stay fixed.
- `converge.yml` — applies the role under test. Do not add `gather_facts: false` here; roles that use `ansible_*` facts require the default (`true`).
- `verify.yml` — runs after converge. Use `gather_facts: false` on the verify play (avoids a redundant second gather). Standard idioms for file content checks: `ansible.builtin.stat` → `ansible.builtin.assert` for existence/permissions; `ansible.builtin.slurp` + `b64decode` filter → `ansible.builtin.assert` for content.

Run the full test cycle with `molecule test` (dependency → destroy → syntax → create → converge → idempotence → verify → destroy). The idempotence phase re-runs converge and fails if any task reports `changed` — confirm all tasks are truly idempotent before declaring done.

## Verification

Prefer focused checks from the target Ansible project root:

```bash
ansible-lint <changed playbook or role>
ansible-playbook --syntax-check <playbook.yml>
ansible-inventory --list
molecule test
```

For inventory-sensitive changes, run the narrowest safe command against the intended inventory and limit. Do not run destructive playbooks against real hosts without explicit approval.