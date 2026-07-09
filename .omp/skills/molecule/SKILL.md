---
name: molecule
description: Author and debug Molecule test scenarios for Ansible roles using the Docker driver.
---

# Molecule Testing

Use this skill when editing `molecule/` scenarios, `converge.yml`, `verify.yml`, `molecule.yml`, or diagnosing molecule test failures.

## Scenario layout

Each scenario lives under `molecule/<scenario>/`:

- `molecule.yml` — driver (`docker`), platform image, provisioner (`ansible`), verifier (`ansible`). Change only the `platforms[].image` field when switching distros; all other keys stay fixed. Use `geerlingguy/docker-<distro>-ansible:latest` images for Ansible-ready containers.
- `converge.yml` — thin playbook that applies the role under test. Do not add `gather_facts: false`; roles using `ansible_*` facts require the default (`true`). Add `become: true` at the play level when the role needs privilege escalation.
- `verify.yml` — assertions run after converge. Set `gather_facts: false` on the verify play (avoids a redundant second fact-gather). Standard idioms:
  - File existence + permissions: `ansible.builtin.stat` → `ansible.builtin.assert` on `stat.stat.exists` and `stat.stat.mode`
  - File content: `ansible.builtin.slurp` (base64) → `ansible.builtin.assert` using `'key=' in (content | b64decode)`
  - Package installed: `ansible.builtin.command: which <pkg>` with `changed_when: false`

## Test lifecycle

`molecule test` runs: dependency → destroy → syntax → create → converge → idempotence → verify → destroy.

- **idempotence**: re-runs converge; fails if any task reports `changed`. All tasks must be genuinely idempotent — debug tasks never report changed, apt/copy/template tasks are idempotent by nature.
- **verify**: assertions only; no role tasks. Never add role tasks to verify.yml.

## Verification

```bash
molecule test           # full cycle
molecule converge       # apply role only (no idempotence/verify/destroy)
molecule verify         # run assertions against an existing instance
molecule destroy        # tear down containers
```

Run from the repo root. Molecule reads `ANSIBLE_ROLES_PATH` from `molecule.yml`'s `provisioner.env` block; do not set it globally.