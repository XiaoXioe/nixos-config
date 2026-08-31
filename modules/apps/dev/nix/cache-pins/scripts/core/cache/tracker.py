"""Channel commit revision and flake lock tracker."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from typing import Dict, Optional

from core.eval.channels import find_flake_dir, get_nix_env, resolve_channel_input
from core.models import ChannelRevInfo

_REV_CACHE: Dict[str, ChannelRevInfo] = {}


def get_channel_revision_info(channel_or_input: Optional[str] = None) -> ChannelRevInfo:
    """Extract revision commit hash and metadata from flake.lock or upstream channel."""
    resolved_input = resolve_channel_input(channel_or_input)
    if resolved_input in _REV_CACHE:
        return _REV_CACHE[resolved_input]

    flake_dir = find_flake_dir()
    clean_channel_key = re.sub(r"[^a-zA-Z0-9_-]", "_", resolved_input)

    # 1. Fast Path: Check local flake.lock directly
    if flake_dir:
        flake_lock = flake_dir / "flake.lock"
        if flake_lock.is_file():
            try:
                data = json.loads(flake_lock.read_text(encoding="utf-8"))
                nodes = data.get("nodes", {})
                root_node = nodes.get(data.get("root", "root"), {})
                root_inputs = root_node.get("inputs", {})

                target_node_name = None
                if resolved_input in root_inputs:
                    target_node_name = root_inputs[resolved_input]
                elif channel_or_input in root_inputs:
                    target_node_name = root_inputs[channel_or_input]
                elif "nixpkgs" in root_inputs and resolved_input == "nixpkgs":
                    target_node_name = root_inputs["nixpkgs"]

                if target_node_name and target_node_name in nodes:
                    locked = nodes[target_node_name].get("locked", {})
                    rev = locked.get("rev") or locked.get("narHash")
                    last_mod = locked.get("lastModified")
                    nar_hash = locked.get("narHash")
                    if rev:
                        info = ChannelRevInfo(
                            channel_input=resolved_input,
                            channel_key=clean_channel_key,
                            revision=str(rev),
                            last_modified=last_mod,
                            nar_hash=nar_hash,
                            is_local_flake=True,
                        )
                        _REV_CACHE[resolved_input] = info
                        return info
            except Exception:
                pass

    # 2. Remote Flake / Channel Resolution via nix flake metadata
    cmd = ["nix", "flake", "metadata", resolved_input, "--json"]
    try:
        res = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=None,
            env=get_nix_env(),
        )
        if res.returncode == 0:
            meta = json.loads(res.stdout)
            locked = meta.get("locked", {})
            rev = (
                meta.get("revision")
                or locked.get("rev")
                or locked.get("narHash")
                or meta.get("fingerprint")
            )
            last_mod = locked.get("lastModified") or meta.get("lastModified")
            nar_hash = locked.get("narHash")
            store_path = meta.get("path")
            locked_url = meta.get("url")

            if rev:
                info = ChannelRevInfo(
                    channel_input=resolved_input,
                    channel_key=clean_channel_key,
                    revision=str(rev),
                    last_modified=last_mod,
                    nar_hash=nar_hash,
                    store_path=store_path,
                    locked_url=locked_url,
                    is_local_flake=False,
                )
                _REV_CACHE[resolved_input] = info
                return info
    except Exception:
        pass

    # 3. Fallback: Hash of input identifier
    fallback_rev = hashlib.sha256(resolved_input.encode("utf-8")).hexdigest()[:16]
    fallback_info = ChannelRevInfo(
        channel_input=resolved_input,
        channel_key=clean_channel_key,
        revision=fallback_rev,
        is_local_flake=False,
    )
    _REV_CACHE[resolved_input] = fallback_info
    return fallback_info
