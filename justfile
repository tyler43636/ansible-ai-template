set shell := ["bash", "-c"]

default:
    @just --list

# Run the CLI locally for testing
run *ARGS:
    python -m ansible_init {{ARGS}}

# Lint the CLI code
lint:
    ruff check cli/
    pyright cli/

# Run CLI tests
test:
    python -m pytest cli/tests/ -v

# Validate all templates render without error
validate-templates:
    python -m ansible_init --dry-run --preset minimal --name test-project