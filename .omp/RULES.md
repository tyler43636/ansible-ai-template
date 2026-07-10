Never commit `.vault_pass`, API keys, or any plaintext secrets.
All Ansible tasks must be idempotent — safe to run more than once.
Use fully qualified collection names for all Ansible modules.
Do not run destructive playbooks against real hosts without explicit user approval.
Run `ansible-lint` against every changed playbook or role before declaring work done; `molecule test` (or `ansible-playbook --syntax-check`) is also required.