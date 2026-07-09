Never commit `.vault_pass`, API keys, or any plaintext secrets.
All Ansible tasks must be idempotent — safe to run more than once.
Use fully qualified collection names for all Ansible modules.
Do not run destructive playbooks against real hosts without explicit user approval.
Run `molecule test` (or at minimum `ansible-playbook --syntax-check`) before declaring a role change done.