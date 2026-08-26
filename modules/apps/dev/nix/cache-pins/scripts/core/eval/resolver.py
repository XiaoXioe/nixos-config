"""Dynamic package candidate resolution, scope traversal, and version parsing utilities."""
import os
import re
from typing import Dict, List, Optional


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
    match = re.search(r"-(\d[\w\.\-]+)$", pkg_full_name)
    if match:
        return match.group(1)
    return "pinned"


def is_path_in_nix_store(store_path: str) -> bool:
    """Check if a store path physically exists in /nix/store (zero subprocess overhead)."""
    if not store_path or not store_path.startswith("/nix/store/"):
        return False
    return os.path.exists(store_path)


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

    if pname:
        clean_pname = pname.replace("pkgs.", "").strip()
        if clean_pname:
            candidates.append(clean_pname)
            p_dash = clean_pname.replace("_", "-")
            p_under = clean_pname.replace("-", "_")
            if p_dash not in candidates:
                candidates.append(p_dash)
            if p_under not in candidates:
                candidates.append(p_under)

    clean_key = target_key.replace("pkgs.", "").strip()
    var_dash = clean_key.replace("_", "-")
    var_under = clean_key.replace("-", "_")

    for k in [clean_key, var_dash, var_under]:
        if k and k not in candidates:
            candidates.append(k)

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
    system: str = "x86_64-linux",
) -> str:
    """Construct a high-performance, single-pass Nix batch evaluation expression.

    Safely traverses dynamic package scopes (top-level, python3Packages, nodePackages,
    gnome, kdePackages, libsForQt5, linuxPackages) using builtins.tryEval.
    """
    entries_nix = []
    for key, cands in target_candidates_map.items():
        cands_str = " ".join(f'"{c}"' for c in cands if c)
        clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", key)
        entries_nix.append(f'    "{clean_key}" = [ {cands_str} ];')

    targets_block = "\n".join(entries_nix)

    return f"""
let
  fl = {flake_target_expr};
  pkgs = fl.legacyPackages.{system} or fl.packages.{system} or {{}};

  safeGet = obj: attr:
    let
      res = builtins.tryEval (obj.${{attr}} or null);
    in
      if res.success then res.value else null;

  # Scope sets to search dynamically
  scopes = [
    pkgs
    (safeGet pkgs "python3Packages")
    (safeGet pkgs "python314Packages")
    (safeGet pkgs "python313Packages")
    (safeGet pkgs "python312Packages")
    (safeGet pkgs "nodePackages")
    (safeGet pkgs "nodePackages_latest")
    (safeGet pkgs "gnome")
    (safeGet pkgs "kdePackages")
    (safeGet pkgs "libsForQt5")
    (safeGet pkgs "linuxPackages")
    (safeGet pkgs "linuxPackages_cachyos")
  ];

  extractMeta = raw:
    let
      chk = builtins.tryEval (
        if raw != null && (raw ? outPath || builtins.isPath raw) then
          let
            drv = if raw ? kernel then raw.kernel else raw;
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
      if chk.success then chk.value else null;

  resolveCandidates = candNames:
    let
      results = builtins.concatLists (
        builtins.map (name:
          builtins.filter (x: x != null) (
            builtins.map (scope:
              if scope != null then
                extractMeta (safeGet scope name)
              else null
            ) scopes
          )
        ) candNames
      );
    in
      if results != [] then builtins.head results else null;

  targetMap = {{
{targets_block}
  }};
in
  builtins.mapAttrs (k: cands: resolveCandidates cands) targetMap
"""
