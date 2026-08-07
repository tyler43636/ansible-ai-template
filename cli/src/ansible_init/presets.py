from dataclasses import dataclass

@dataclass
class Preset:
    name: str
    description: str
    collections: list[str]
    available: bool = True

PRESETS = {
    "minimal": Preset(
        name="minimal",
        description="Empty skeleton with community.general — for greenfield projects",
        collections=["community.general"],
    ),
    "homelab": Preset(
        name="homelab",
        description="Application deployment with Docker roles and backup scaffolding",
        collections=["community.general", "community.docker"],
        available=True,
    ),
    "sysadmin": Preset(
        name="sysadmin",
        description="Enterprise Linux fleet management with hardening and compliance",
        collections=["community.general", "ansible.posix"],
        available=True,
    ),
}
