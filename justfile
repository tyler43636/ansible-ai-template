set shell := ["bash", "-c"]

default:
    @just --list

install:
    ansible-galaxy collection install -r requirements.yml
    if [ ! -f .vault_pass ]; then echo 'dummy_vault_pass_for_ci_testing' > .vault_pass && chmod 600 .vault_pass; fi

syntax: install
    ansible-playbook --syntax-check playbooks/*.yml
    ansible-inventory --list
    pyright scripts/
    find . -type f -name "*.nix" -not -path "*/.*" -not -path "*/nix/store/*" -exec nix-instantiate --parse {} + >/dev/null
    find . -type f -name "*.sh" -not -path "*/.*" -exec bash -n {} +

lint: install
    ansible-lint
    ruff check scripts/
    statix check .
    find . -type f -name "*.sh" -not -path "*/.*" -exec shellcheck {} +

molecule: install
    molecule test

test: lint syntax molecule
