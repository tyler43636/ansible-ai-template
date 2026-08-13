---
name: nix-dev-shell
globs: ["flake.nix", "flake.lock"]
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
1. Search Nixpkgs to confirm the package name using `mcp__nix_nix` or check version history using `mcp__nix_versions` before editing `flake.nix`, rather than guessing package names.
2. Add the package to the `devShells.default` package list in `flake.nix`.
3. Update the environment:
   - Run `direnv reload` or `direnv allow`.
   - **Stale Cache?** If the new packages aren't picked up, `nix-direnv` might have a stale cache. Force a rebuild with: `rm -rf .direnv && direnv allow`.
4. **Agent Shell Context:** Running `direnv allow` via a bash tool call updates the project environment, but *not* your current active shell session's `PATH`. To use the new tools immediately, you MUST either:
   - Inject them into your current shell: `eval "$(direnv export bash)"`
   - Or run them explicitly inside the flake context: `nix develop --command <tool>`