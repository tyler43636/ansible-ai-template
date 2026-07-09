---
name: vault
description: Handle Ansible Vault encrypted strings and vault password files in this repository.
---

# Ansible Vault

Use this skill when working with encrypted variables, vault password files, or `ansible-vault` commands in this repository.

## Repository vault setup

The vault password file is `.vault_pass` in the repo root. It is gitignored and must be created manually on each new machine:

```bash
echo 'your_vault_password' > .vault_pass
chmod 600 .vault_pass
```

`ansible.cfg` sets `vault_password_file = ./.vault_pass`, so all `ansible-playbook` and `ansible-vault` commands pick it up automatically.

## Encrypting a new secret

```bash
ansible-vault encrypt_string 'SECRET_VALUE' --name 'variable_name'
```

Paste the output block directly into a vars file or `group_vars/`. Reference the variable by name in tasks and templates — no special syntax needed.

## Decrypting for inspection

```bash
ansible localhost -m debug -a "var=variable_name" -e "@vars_file.yml"
```

Do not commit plaintext secrets. Do not log vault passwords. Do not store `.vault_pass` in environment variables in scripts that are committed.