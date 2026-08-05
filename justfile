set shell := ["bash", "-c"]

default:
    @just --list

install:
    ansible-galaxy collection install -r requirements.yml
    if [ ! -f .vault_pass ]; then echo 'dummy_vault_pass_for_ci_testing' > .vault_pass && chmod 600 .vault_pass; fi

syntax: install
    ansible-playbook --syntax-check playbooks/*.yml
    ansible-inventory --list

lint: install
    ansible-lint

molecule: install
    molecule test

test: lint syntax molecule
