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
- Do not check in secrets. Use the project's vault/SOPS mechanism or documented secret path.

## Verification

Prefer focused checks from the target Ansible project root:

```bash
ansible-lint <changed playbook or role>
ansible-playbook --syntax-check <playbook.yml>
molecule test
```

For inventory-sensitive changes, run the narrowest safe command against the intended inventory and limit. Do not run destructive playbooks against real hosts without explicit approval.
