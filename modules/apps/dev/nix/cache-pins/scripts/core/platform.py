"""Dynamic system architecture and platform detection for Nix."""
import os
import platform
import sys


def get_current_system() -> str:
    """Detect current Nix system architecture tuple dynamically (e.g. x86_64-linux, aarch64-linux)."""
    env_sys = os.environ.get("NIX_SYSTEM") or os.environ.get("NCP_SYSTEM")
    if env_sys and env_sys.strip():
        return env_sys.strip()

    machine = platform.machine().lower()
    os_name = sys.platform.lower()

    arch_map = {
        "x86_64": "x86_64",
        "amd64": "x86_64",
        "aarch64": "aarch64",
        "arm64": "aarch64",
        "i686": "i686",
        "i386": "i686",
        "armv7l": "armv7l",
    }

    nix_arch = arch_map.get(machine, machine)

    if "linux" in os_name:
        return f"{nix_arch}-linux"
    elif "darwin" in os_name:
        return f"{nix_arch}-darwin"

    return "x86_64-linux"
