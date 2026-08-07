import argparse
import os
import sys
from pathlib import Path
from .presets import PRESETS
from .renderer import render_project

def main():
    parser = argparse.ArgumentParser(description="Scaffold a new Ansible project.")
    parser.add_argument("--name", help="Project name")
    parser.add_argument("--dir", help="Project directory")
    parser.add_argument("--preset", help="Preset to use")
    parser.add_argument("--vault", action="store_true", help="Enable Ansible Vault")
    parser.add_argument("--molecule", action="store_true", help="Enable Molecule test scaffolding")
    parser.add_argument("--molecule-driver", help="Molecule driver (docker/podman)")
    parser.add_argument("--git", action="store_true", help="Initialize git repository")
    parser.add_argument("--force", action="store_true", help="Force overwrite if directory exists")
    parser.add_argument("--dry-run", action="store_true", help="Dry run template render test")
    
    # If any arguments are provided, use non-interactive mode
    if len(sys.argv) > 1:
        args = parser.parse_args()
        
        name = args.name or "my-ansible-project"
        out_dir = args.dir or f"./{name}"
        preset_name = args.preset or "minimal"
        
        context = {
            "project_name": name,
            "preset": preset_name,
            "vault_enabled": args.vault,
            "molecule_enabled": args.molecule,
            "molecule_driver": args.molecule_driver or "docker",
            "git_enabled": args.git,
            "collections": PRESETS[preset_name].collections if preset_name in PRESETS else ["community.general"],
        }
        
        if args.dry_run:
            print(f"Dry run successful for {name}")
            return
            
        render_project(context, out_dir)
        print(f"Scaffolded project in {out_dir}")
        return

    # Interactive mode
    print("\n\033[1mAnsible Project Scaffolder\033[0m\n")
    
    # 1. Project name
    default_name = os.path.basename(os.getcwd()) or "my-ansible-project"
    name = input(f"Project name ({default_name}): ").strip() or default_name
    
    # 2. Project directory
    default_dir = f"./{name}"
    out_dir = input(f"Project directory ({default_dir}): ").strip() or default_dir
    
    out_path = Path(out_dir)
    if out_path.exists() and any(out_path.iterdir()):
        force = input(f"Directory {out_dir} exists and is not empty. Continue? [y/N]: ").strip().lower()
        if force != 'y':
            print("Aborted.")
            sys.exit(1)
            
    # 3. Preset selection
    print("\nPresets:")
    presets_list = list(PRESETS.values())
    for i, p in enumerate(presets_list):
        status = "" if p.available else " (coming soon)"
        print(f"{i+1}) {p.name}{status} - {p.description}")
        
    while True:
        preset_idx = input("Select preset (1): ").strip() or "1"
        try:
            idx = int(preset_idx) - 1
            if 0 <= idx < len(presets_list):
                selected_preset = presets_list[idx]
                if not selected_preset.available:
                    print(f"Preset '{selected_preset.name}' is not yet available.")
                    continue
                break
        except ValueError:
            pass
        print("Invalid selection.")
        
    preset_name = selected_preset.name
    
    # 4. Vault setup
    vault = input("Set up Ansible Vault? [Y/n]: ").strip().lower() != 'n'
    
    # 5. Molecule testing
    molecule = input("Include Molecule test scaffolding? [Y/n]: ").strip().lower() != 'n'
    driver = "docker"
    if molecule:
        driver_sel = input("Molecule driver [1) docker (default), 2) podman]: ").strip() or "1"
        if driver_sel == "2":
            driver = "podman"
            
    # 6. Git init
    git = input("Initialize git repository? [Y/n]: ").strip().lower() != 'n'
    
    # 7. Summary
    print("\n\033[1mSummary:\033[0m")
    print(f"  Project name: {name}")
    print(f"  Directory:    {out_dir}")
    print(f"  Preset:       {preset_name}")
    print(f"  Vault:        {'Yes' if vault else 'No'}")
    print(f"  Molecule:     {'Yes (' + driver + ')' if molecule else 'No'}")
    print(f"  Git:          {'Yes' if git else 'No'}")
    
    confirm = input("\nCreate project? [Y/n]: ").strip().lower() != 'n'
    if not confirm:
        print("Aborted.")
        sys.exit(0)
        
    context = {
        "project_name": name,
        "preset": preset_name,
        "vault_enabled": vault,
        "molecule_enabled": molecule,
        "molecule_driver": driver,
        "git_enabled": git,
        "collections": selected_preset.collections,
    }
    
    print("\nScaffolding project...")
    render_project(context, out_dir)
    print(f"\n\033[1;32mDone!\033[0m Project created at {out_dir}")
    print("\nNext steps:")
    print(f"  cd {out_dir}")
    print("  direnv allow  # or: nix develop github:tyler43636/ansible-ai-template")
    print("  just install")

if __name__ == "__main__":
    main()
