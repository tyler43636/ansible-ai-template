# ansible-ai-template (ansible-init)

A Nix-powered Ansible project scaffolder with an AI-native development environment. 

`ansible-init` is an interactive Python CLI that rapidly generates new Ansible projects complete with a pre-configured, reproducible toolchain.

## Quickstart

To run the scaffolder from anywhere without installing anything (requires Nix with flakes):

```bash
nix develop github:tyler43636/ansible-ai-template --command ansible-init
```

Follow the interactive prompts to create your project. Once scaffolded, simply enter the directory and `direnv allow` (or `nix develop`) to enter the fully configured environment.

## Available Presets

| Preset | Description | Status |
|--------|-------------|--------|
| **minimal** | Empty skeleton with `community.general` — perfect for greenfield projects. | Available |
| **homelab** | Application deployment with Docker roles and backup scaffolding. | Available |
| **sysadmin** | Enterprise Linux fleet management with hardening and compliance. | Available |

## Molecule Test Scaffolding

If you have an existing Ansible project or role and want to inject Molecule testing into it, you can use the `molecule-init` tool:

```bash
cd my-existing-project
nix develop github:tyler43636/ansible-ai-template --command molecule-init
```

This will prompt you for your preferred driver (Docker or Podman) and render the `molecule/` directory structure directly into your current working directory without overwriting your existing files.

## What's Included

When you scaffold a project, you receive:
- **Reproducible Environment**: A `flake.nix` driven `nix develop` shell.
- **Ansible Tools**: `ansible`, `ansible-lint`, `molecule`.
- **Language Servers**: `ansible-language-server`, `yaml-language-server`, `bash-language-server`, `pyright`, `ruff`, `marksman`.
- **Task Runner**: A `justfile` with standard recipes (`just install`, `just lint`, `just test`).
- **AI Integration**: A `.omp/` directory customized for Oh My Pi, pre-loaded with specialized agent skills (Ansible, Molecule, Vault, Nix, Jinja2).

## Developing the Scaffolder

If you want to hack on `ansible-init` itself:

1. Clone this repository and enter the shell:
   ```bash
   git clone https://github.com/tyler43636/ansible-ai-template.git
   cd ansible-ai-template
   direnv allow
   ```

2. Available `just` recipes:
   - `just run` - Run the CLI locally.
   - `just lint` - Lint the Python CLI code.
   - `just test` - Run CLI tests.
   - `just validate-templates` - Dry-run rendering test for templates.