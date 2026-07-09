---
name: nix-dev-shell
description: Add dependencies, manage the development environment, and handle flake.nix updates.
---

# Nix Development Environment

This repository uses Nix flakes and `direnv` to manage the local development shell. **The environment is immutable.**

## Core Rules
1. **Never use global package managers**: Do not run `apt-get`, `brew`, `pip install`, `npm install -g`, or `cargo install` to add tools.
2. **Add packages via flake.nix**: To add a new CLI tool or dependency, you MUST edit the `packages = with pkgs; [...]` block inside `flake.nix`.
3. **Python dependencies**: Add Python packages using the `python3.withPackages (ps: with ps; [ ... ])` pattern already present in the flake.
4. **Reloading**: After modifying `flake.nix`, the shell must be updated by running `direnv allow` or `direnv reload`.

## Workflow
If the user asks for a new tool (e.g., "we need `terraform` for this playbook"):
1. Search Nixpkgs to confirm the package name (or infer if standard).
2. Use the `edit` tool to add the package to the `devShells.default` package list in `flake.nix`.
3. Run `direnv reload` to materialize the package in the environment.