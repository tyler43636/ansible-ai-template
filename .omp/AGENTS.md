# AGENTS.md

This file provides guidance for agentic coding agents working in this repository.

## Project Overview

`ansible-ai-template` is a tool repository that provides `ansible-init`, an interactive Python CLI for scaffolding new Ansible projects. It also contains the template files (Jinja2 and static) that the CLI uses to generate these projects.

## Repository Structure

```
.
├── cli/                     # Python CLI source code
│   ├── pyproject.toml
│   └── src/ansible_init/
├── templates/               # Project templates used by the CLI
│   ├── shared/              # Common files for all presets
│   └── minimal/             # Overlay files for the 'minimal' preset
├── flake.nix                # Nix flake defining the dev shell + builds the CLI
├── justfile                 # Task runner recipes for CLI development
├── README.md                # Tool documentation
└── .omp/                    # OMP agent config for developing the tool
```

## Development Commands

Run these inside the Nix dev shell (`nix develop`):

```bash
# Run the CLI locally for testing
just run [args]

# Lint the Python CLI code
just lint

# Run CLI tests (if any)
just test

# Validate all templates render without error
just validate-templates
```

## Template System

- Templates live in `templates/`.
- `templates/shared/` contains files that go into every scaffolded project.
- `templates/<preset>/` contains preset-specific files. If a file exists here, it OVERWRITES the shared file.
- Files ending in `.j2` are rendered as Jinja2 templates (with `.j2` stripped from the output filename).
- All other files are copied verbatim.

## CLI Architecture

- Standard Python project using `pyproject.toml`.
- Packaged via `flake.nix` as a Nix derivation (`buildPythonApplication`).
- Entry point is `ansible_init.cli:main`.
- Dependencies: `jinja2`.

## Agent Skills

Five project skills are available via `skill://`:
- `skill://ansible` — Ansible role/playbook authoring, lint, and verification
- `skill://molecule` — Molecule test scenario authoring and debugging
- `skill://vault` — Ansible Vault encrypted secrets handling
- `skill://nix-dev-shell` — Modifying the Nix development environment (`flake.nix`)
- `skill://jinja2-templating` — Jinja2 template authoring rules and safety

(Note: These skills are primarily useful when editing the Ansible templates in `templates/`, rather than the Python CLI code).