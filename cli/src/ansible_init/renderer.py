import os
import shutil
import subprocess
import secrets
import string
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

def render_project(context: dict, output_dir: str):
    template_dir = os.environ.get("ANSIBLE_INIT_TEMPLATE_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "templates"))
    
    env = Environment(
        loader=FileSystemLoader(template_dir),
        keep_trailing_newline=True,
    )
    
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)
    
    preset = context.get("preset", "minimal")
    
    # Render a directory
    def render_directory(src_rel_path: str):
        src_full_path = Path(template_dir) / src_rel_path
        if not src_full_path.exists():
            return
            
        for root, dirs, files in os.walk(src_full_path):
            rel_root = Path(root).relative_to(src_full_path)
            target_dir = out_path / rel_root
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
                    if target_file.exists():
                        target_file.chmod(0o644)
                    shutil.copy2(src_file, target_file)
                    target_file.chmod(0o644)

    # 1. Render shared
    render_directory("shared")
    
    # 2. Render preset
    render_directory(preset)
    
    # 3. Post-render steps
    if context.get("vault_enabled"):
        chars = string.ascii_letters + string.digits
        pwd = ''.join(secrets.choice(chars) for _ in range(32))
        vault_file = out_path / ".vault_pass"
        vault_file.write_text(pwd + "\n")
        vault_file.chmod(0o600)
        
    if not context.get("molecule_enabled"):
        molecule_dir = out_path / "molecule"
        if molecule_dir.exists():
            shutil.rmtree(molecule_dir)
            
    if context.get("git_enabled"):
        subprocess.run(["git", "init"], cwd=out_path, check=True, capture_output=True)
        subprocess.run(["git", "add", "."], cwd=out_path, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "Initial project scaffold via ansible-init"], cwd=out_path, check=True, capture_output=True)
