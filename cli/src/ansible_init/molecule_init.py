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
    
    context = {
        "project_name": os.path.basename(cwd),
        "preset": "minimal", # Uses minimal preset's basic molecule files by default
        "vault_enabled": False,
        "molecule_enabled": True,
        "molecule_driver": driver,
        "git_enabled": False,
        "collections": [],
    }
    
    # Custom rendering logic just for molecule/ directory
    template_dir = os.environ.get("ANSIBLE_INIT_TEMPLATE_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "templates"))
    from jinja2 import Environment, FileSystemLoader
    env = Environment(
        loader=FileSystemLoader(template_dir),
        keep_trailing_newline=True,
    )
    
    out_path = Path(cwd)
    molecule_out = out_path / "molecule"
    if molecule_out.exists():
        print("molecule/ directory already exists. Aborting.")
        sys.exit(1)
        
    src_molecule = Path(template_dir) / "shared" / "molecule"
    if not src_molecule.exists():
        print(f"Error: Could not find templates at {src_molecule}")
        sys.exit(1)
        
    for root, dirs, files in os.walk(src_molecule):
        rel_root = Path(root).relative_to(src_molecule)
        target_dir = molecule_out / rel_root
        target_dir.mkdir(parents=True, exist_ok=True)
        
        for file in files:
            src_file = Path(root) / file
            is_j2 = file.endswith(".j2")
            
            if is_j2:
                target_file = target_dir / file[:-3]
                rel_template_path = src_file.relative_to(template_dir).as_posix()
                template = env.get_template(rel_template_path)
                content = template.render(**context)
                if target_file.exists():
                    target_file.chmod(0o644)
                target_file.write_text(content)
            else:
                target_file = target_dir / file
                import shutil
                if target_file.exists():
                    target_file.chmod(0o644)
                shutil.copy2(src_file, target_file)
                target_file.chmod(0o644)

    print(f"\n\033[1;32mDone!\033[0m Molecule scaffolding created in {cwd}/molecule/")

if __name__ == "__main__":
    main()
