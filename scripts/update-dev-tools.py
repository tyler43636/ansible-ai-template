#!/usr/bin/env python3
from __future__ import annotations

import argparse
import concurrent.futures
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

PLATFORMS = {
    "x86_64-linux": "linux-x64",
    "aarch64-linux": "linux-arm64",
    "x86_64-darwin": "darwin-x64",
    "aarch64-darwin": "darwin-arm64",
}


def find_flake():
    current = Path.cwd()
    for directory in [current, *current.parents]:
        flake = directory / "flake.nix"
        if flake.is_file():
            return flake
    return Path("flake.nix")


def get_latest_version():
    url = "https://api.github.com/repos/can1357/oh-my-pi/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "oh-my-pi-updater"})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            return data["tag_name"]
    except (urllib.error.URLError, ValueError, KeyError) as exc:
        sys.exit(f"Error fetching latest release from GitHub API: {exc}")


def prefetch_hash(version, system, platform):
    url = f"https://github.com/can1357/oh-my-pi/releases/download/{version}/omp-{platform}"
    print(f"Prefetching hash for {system} ({url})...")
    try:
        res = subprocess.run(
            ["nix-prefetch-url", url],
            capture_output=True,
            text=True,
            check=True,
        )
        hash_val = res.stdout.strip().split("\n")[-1].strip()
        if not hash_val:
            raise ValueError("Empty hash returned")
        return system, hash_val
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"Failed to prefetch {url}:\nstdout: {exc.stdout}\nstderr: {exc.stderr}"
        ) from exc
    except Exception as exc:
        raise RuntimeError(
            f"Error executing nix-prefetch-url for {system}: {exc}"
        ) from exc


def update_omp(flake_path: Path, target_ver: str | None = None, force: bool = False) -> bool:
    try:
        content = flake_path.read_text(encoding="utf-8")
        current_ver_match = re.search(r'ompVersion\s*=\s*"([^"]+)"', content)
        current_ver = current_ver_match.group(1) if current_ver_match else "unknown"

        if target_ver:
            if not target_ver.startswith("v") and target_ver[0].isdigit():
                target_ver = f"v{target_ver}"
        else:
            print("Querying GitHub for latest oh-my-pi release...")
            target_ver = get_latest_version()

        print(f"Current version: {current_ver}")
        print(f"Target version:  {target_ver}")

        if current_ver == target_ver and not force:
            print(f"oh-my-pi is already up to date ({target_ver}).")
            return False

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=len(PLATFORMS)
        ) as executor:
            futures = [
                executor.submit(
                    prefetch_hash, target_ver, sys_name, plat_name
                )
                for sys_name, plat_name in PLATFORMS.items()
            ]
            hashes = dict(f.result() for f in futures)

        print("\nAll hashes collected:")
        for sys_name, hash_val in hashes.items():
            print(f"  {sys_name}: {hash_val}")

        new_content = re.sub(
            r'(ompVersion\s*=\s*")[^"]+(")',
            rf"\g<1>{target_ver}\g<2>",
            content,
            count=1,
        )

        def replace_hashes(match):
            block = match.group(0)
            for sys_name, hash_val in hashes.items():
                block = re.sub(
                    rf'(system\s*==\s*"{sys_name}"\s+then\s+")[^"]*(")',
                    rf"\g<1>{hash_val}\g<2>",
                    block,
                )
            return block

        new_content = re.sub(
            r"ompHash\s*=\s*[^;]+;", replace_hashes, new_content, flags=re.DOTALL
        )

        if new_content == content and not force:
            print("No changes required in flake.nix.")
            return False

        flake_path.write_text(new_content, encoding="utf-8")
        print(f"\nSuccessfully updated {flake_path} to {target_ver}.")
        return True

    except (OSError, RuntimeError, ValueError) as exc:
        sys.exit(f"Error updating oh-my-pi: {exc}")


def update_flake_inputs(flake_path: Path) -> None:
    print("\nUpdating Nix flake inputs (nix flake update)...")
    try:
        subprocess.run(["nix", "flake", "update"], cwd=str(flake_path.parent), check=True)
        print("Successfully updated flake inputs in flake.lock.")
    except (subprocess.CalledProcessError, OSError) as exc:
        sys.exit(f"Error updating flake inputs: {exc}")


def main():
    parser = argparse.ArgumentParser(
        description="Update development tools and Nix flake inputs"
    )
    parser.add_argument(
        "-v",
        "--version",
        "--omp-version",
        dest="omp_version",
        help="Target version tag for oh-my-pi (e.g. v17.2.9). Defaults to latest release on GitHub.",
    )
    parser.add_argument(
        "-f",
        "--flake",
        type=Path,
        default=find_flake(),
        help="Path to flake.nix",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force hash prefetch and rewrite even if version is unchanged",
    )
    args = parser.parse_args()

    flake_path = args.flake
    if not flake_path.is_file():
        sys.exit(f"Error: {flake_path} does not exist or is not a file.")

    update_omp(flake_path, args.omp_version, args.force)
    update_flake_inputs(flake_path)
    print("\nAll dev tools updated. Run 'direnv reload' or 'nix develop' to apply updates.")


if __name__ == "__main__":
    main()
