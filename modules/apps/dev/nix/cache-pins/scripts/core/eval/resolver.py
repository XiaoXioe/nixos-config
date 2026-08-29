"""Dynamic package candidate resolution, scope traversal, and version parsing utilities."""

import os
import re
from typing import Dict, List, Optional

from core.platform import get_current_system


def extract_version_from_store_path(store_path: str) -> str:
    """Extract human-readable version from a Nix store path string."""
    if not store_path:
        return "unknown"
    base = os.path.basename(store_path.rstrip("/"))
    # Remove the 32-char hash prefix (e.g. 86nhn0hbzqww5s85573nyfw5ci1xc882-rclone-1.75.0)
    parts = base.split("-", 1)
    if len(parts) < 2:
        return "unknown"
    pkg_full_name = parts[1]
    match = re.search(r"-(\d[\w\.\-\+]+)$", pkg_full_name)
    if match:
        return match.group(1)
    return "pinned"


def is_path_in_nix_store(store_path: str, verify_validity: bool = True) -> bool:
    """Check if a store path physically exists and is registered valid in Nix SQLite db."""
    if not store_path or not store_path.startswith("/nix/store/"):
        return False
    if not os.path.exists(store_path):
        return False
    if not verify_validity:
        return True
    import subprocess

    res = subprocess.run(
        ["nix-store", "--check-validity", store_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return res.returncode == 0


def compare_versions(v1: str, v2: str) -> int:
    """Compare two version strings (SemVer, date-based, or alpha/beta).

    Returns:
         1 if v1 > v2 (v1 is newer)
         0 if v1 == v2
        -1 if v1 < v2 (v1 is older / downgrade)
    """
    if not v1 or not v2 or v1 == "unknown" or v2 == "unknown":
        return 0 if v1 == v2 else (1 if v1 and v1 != "unknown" else -1)

    if v1 == v2:
        return 0

    nums1 = [int(n) for n in re.findall(r"\d+", v1)]
    nums2 = [int(n) for n in re.findall(r"\d+", v2)]

    if nums1 and nums2:
        for n1, n2 in zip(nums1, nums2):
            if n1 > n2:
                return 1
            elif n1 < n2:
                return -1
        if len(nums1) > len(nums2):
            return 1
        elif len(nums1) < len(nums2):
            return -1

    return 1 if v1 > v2 else -1


def generate_candidate_names(target_key: str, pname: Optional[str] = None) -> List[str]:
    """Generate ordered list of candidate attribute names for Nixpkgs scope resolution."""
    candidates: List[str] = []

    def add_variants(base: str) -> None:
        if not base:
            return
        b_clean = base.replace("pkgs.", "").strip()
        b_dash = b_clean.replace("_", "-")
        b_under = b_clean.replace("-", "_")
        for v in [b_clean, b_dash, b_under]:
            if v and v not in candidates:
                candidates.append(v)
        # Prefix stripping for nested scopes like nerd-fonts, pythonPackages, etc.
        prefixes = [
            "nerd-fonts-",
            "nerd_fonts_",
            "nerdfonts-",
            "nerdfonts_",
            "python3Packages.",
            "python3Packages-",
            "python3Packages_",
            "nodePackages.",
            "nodePackages-",
            "nodePackages_",
            "gnome.",
            "kdePackages.",
            "libsForQt5.",
        ]
        for pfx in prefixes:
            if b_clean.startswith(pfx):
                sub = b_clean[len(pfx) :]
                sub_dash = sub.replace("_", "-")
                sub_under = sub.replace("-", "_")
                for sv in [sub, sub_dash, sub_under]:
                    if sv and sv not in candidates:
                        candidates.append(sv)

    if pname:
        add_variants(pname)

    add_variants(target_key)

    # Common Nixpkgs alias suffixes
    common_suffixes = [
        "-desktop",
        "-desktopeditors",
        "_desktop",
        "-bin",
        "-cli",
        "-gui",
        "-with-plugins",
        "-sdl",
        "-qt",
    ]
    for k in list(candidates):
        for suf in common_suffixes:
            variant = f"{k}{suf}"
            if variant not in candidates:
                candidates.append(variant)

    return candidates


def build_nix_batch_eval_expression(
    target_candidates_map: Dict[str, List[str]],
    flake_target_expr: str,
    system: Optional[str] = None,
) -> str:
    """Construct a high-performance, single-pass Nix batch evaluation expression.

    Uses strictly lazy recursive early-exit evaluation to resolve package candidates across scopes
    (top-level pkgs, nerd-fonts, python3Packages, nodePackages, gnome, kdePackages, libsForQt5, linuxPackages)
    without forcing evaluation of unused thunks or unrelated attribute sets.
    """
    effective_system = system or get_current_system()

    entries_nix = []
    for key, cands in target_candidates_map.items():
        cands_str = " ".join(f'"{c}"' for c in cands if c)
        clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", key)
        entries_nix.append(f'    "{clean_key}" = [ {cands_str} ];')

    targets_block = "\n".join(entries_nix)

    return f"""
let
  fl = {flake_target_expr};
  targetSystem = "{effective_system}";
  pkgs = fl.legacyPackages.${{targetSystem}} or fl.packages.${{targetSystem}} or (
    if builtins ? currentSystem then
      fl.legacyPackages.${{builtins.currentSystem}} or fl.packages.${{builtins.currentSystem}} or {{}}
    else {{}}
  );

  extractMeta = drvRaw:
    let
      res = builtins.tryEval (
        if drvRaw != null && (drvRaw ? outPath || builtins.isPath drvRaw) then
          let
            drv = if drvRaw ? kernel then drvRaw.kernel else drvRaw;
            sp = builtins.unsafeDiscardStringContext (toString (drv.outPath or drv));
            v = drv.version or (if drv ? pname then "pinned" else "unknown");
            mp = drv.meta.mainProgram or (drv.pname or null);
            pn = drv.pname or null;
          in {{
            storePath = sp;
            version = v;
            mainProgram = mp;
            pname = pn;
          }}
        else null
      );
    in
      if res.success then res.value else null;

  # Scope getter yang dievaluasi secara thunked/lazy
  getScope = scopeName:
    if scopeName == "pkgs" then pkgs
    else if pkgs ? ${{scopeName}} then
      let r = builtins.tryEval pkgs.${{scopeName}}; in if r.success then r.value else null
    else null;

  scopeNames = [
    "nerd-fonts"
    "nerdfonts"
    "pkgs"
    "python3Packages"
    "python314Packages"
    "python313Packages"
    "python312Packages"
    "nodePackages"
    "nodePackages_latest"
    "gnome"
    "kdePackages"
    "libsForQt5"
    "linuxPackages"
    "linuxPackages_cachyos"
  ];

  # Recursive early-exit traversal: berhenti segera setelah kandidat pertama ditemukan di suatu scope
  findCandidate = candList:
    if candList == [] then null
    else
      let
        cand = builtins.head candList;
        findInScope = sList:
          if sList == [] then null
          else
            let
              sName = builtins.head sList;
              scope = getScope sName;
              meta = if scope != null && (scope ? ${{cand}}) then
                extractMeta (let r = builtins.tryEval scope.${{cand}}; in if r.success then r.value else null)
              else null;
            in
              if meta != null then meta
              else findInScope (builtins.tail sList);
        res = findInScope scopeNames;
      in
        if res != null then res
        else findCandidate (builtins.tail candList);

  targetMap = {{
{targets_block}
  }};
in
  builtins.mapAttrs (k: cands: findCandidate cands) targetMap
"""
