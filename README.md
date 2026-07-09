# Ansible AI Template

A clone-and-go starting point for any Ansible project, bundled with a Nix dev shell that provides the full Ansible toolchain, an oh-my-pi Ansible skill, a best-practices project skeleton, and molecule test scaffolding.

## Quickstart

1. Enter the development shell (requires Nix):
   ```bash
   nix develop
   ```
   Or if you use `direnv`, simply `direnv allow`.

2. Install required collections:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

3. Run the example playbook against the local testing inventory:
   ```bash
   ansible-playbook playbooks/example.yml
   ```

## Testing with Molecule

The project includes scaffolding for molecule tests using Docker.

```bash
molecule test
```
*(Requires the Docker daemon to be running)*

## AI Agent Integration

This template is configured with an Ansible MCP server (`.mcp.json`), a custom Ansible skill for Oh My Pi, and guidance files (`CLAUDE.md`, `AGENTS.md`) designed to help AI coding assistants correctly navigate and modify the infrastructure code.
