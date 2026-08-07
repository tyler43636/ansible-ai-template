import os
import sys
import argparse
from pathlib import Path
from .renderer import render_project

def main():
    parser = argparse.ArgumentParser(description="Add Molecule test scaffolding to an existing Ansible project or role.")
    parser.add_argument("--driver", help="Molecule driver (docker/podman)")
    
    if len(sys.argv) > 1:
        args = parser.parse_args()
        driver = args.driver or "docker"
    else:
        print("\n\033[1mMolecule Test Scaffolder\033[0m\n")
        driver_sel = input("Molecule driver [1) docker (default), 2) podman]: ").strip() or "1"
        driver = "podman" if driver_sel == "2" else "docker"

    cwd = os.getcwd()
    molecule_out = Path(cwd) / "molecule"
    if molecule_out.exists():
        print("molecule/ directory already exists. Aborting.")
        sys.exit(1)
    
    context = {
        "project_name": os.path.basename(cwd),
        "preset": "minimal", # Uses minimal preset's basic molecule files by default
        "vault_enabled": False,
        "molecule_enabled": True,
        "molecule_driver": driver,
        "git_enabled": False,
        "collections": [],
    }
    
    render_project(context, cwd, only_paths=["molecule"])

    print(f"\n\033[1;32mDone!\033[0m Molecule scaffolding created in {cwd}/molecule/")

if __name__ == "__main__":
    main()
