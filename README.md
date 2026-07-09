# Ansible AI Template

A clone-and-go starting point for any Ansible project, bundled with a Nix dev shell that provides the full Ansible toolchain, a best-practices project skeleton, and Molecule test scaffolding.

## AI Agent Integration

This template is designed from the ground up for agentic coding. 

**Oh My Pi (OMP) Native Support**
The repository uses the native `.omp/` project configuration layout for zero-configuration AI capabilities:
- **Skills** (`.omp/skills/`): Domain-specific knowledge for `ansible`, `molecule`, and `vault`. Automatically discovered by OMP when you enter the project.
- **Agents** (`.omp/agents/`): Contains the `ansible-reviewer` custom agent specialized in reviewing Ansible roles for idempotency and style.
- **MCP Server** (`.omp/mcp.json`): Configures an Ansible MCP server (`ansible-mcp-server`) that provides tools for the AI to ping hosts, run syntax checks, run playbooks, and list inventory. (Requires `npm install -g ansible-mcp-server`).
- **Rules & Context** (`.omp/RULES.md`, `.omp/AGENTS.md`): Automatically injected into the agent's context to enforce strict repository conventions.

**Fallbacks**
The template also provides `CLAUDE.md`, root `AGENTS.md`, and `.mcp.json` at the root as fallbacks for other AI assistants like Claude Code or Cursor.

## Quickstart

1. **Enter the development shell** (requires [Nix](https://nixos.org/download/)):
   ```bash
   nix develop
   ```
   Or if you use `direnv`, simply `direnv allow`.
   The shell provides Ansible, Molecule, ansible-lint, and other required tooling.

2. **Install required collections**:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

3. **Initialize Vault (Optional)**:
   The project is configured to use `.vault_pass` for Ansible Vault. Create it before running playbooks that require encrypted variables:
   ```bash
   echo 'your_vault_password' > .vault_pass
   chmod 600 .vault_pass
   ```

4. **Run the example playbook** against the local testing inventory:
   ```bash
   ansible-playbook playbooks/example.yml
   ```

## Testing with Molecule

The project includes scaffolding for molecule tests using Docker. Molecule will spin up an isolated container, apply the role, verify idempotency, and run assertions.

```bash
molecule test
```
*(Requires the Docker daemon to be running on your host)*

## Structure

```
.
├── ansible.cfg              # Ansible configuration
├── flake.nix                # Nix dev shell and dependencies
├── inventory/               # Host definitions and group_vars
├── playbooks/               # Playbooks mapping hosts to roles
├── roles/                   # Modular Ansible roles
├── molecule/                # Docker-based testing scenarios
└── .omp/                    # Native config for Oh My Pi (Agents, Skills, MCP)
```
