set shell := ["bash", "-c"]

default:
    @just --list

install:
    ansible-galaxy collection install -r requirements.yml

syntax: install
    ansible-playbook --syntax-check playbooks/*.yml
    ansible-inventory --list

lint: install
    ansible-lint

molecule: install
    molecule test

test: lint syntax molecule
