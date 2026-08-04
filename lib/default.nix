# selfLib — Composed library for nixos-config.
# No logic lives here; each domain has its own focused sub-module.
#
# Sub-module map:
#   features.nix      → mapFeatures (feature-toggle transformer)
#   hm.nix            → mkHmSymlinks (out-of-store symlink helper)
#   fs.nix            → scanPaths, getVpnFiles (filesystem helpers)
#   audio.nix         → mkEqFilterString (PipeWire EQ renderer)
#   shell/            → mkApp, mkShellCompletions (shell app builders)
#   network/          → warpProxyEnv, mkWarpWaitScript (WARP helpers)
#   browser-addons/   → browserAddonsFor (Firefox/Zen/Tor policy builders)
#   modules/mkModule/ → mkModule (unified NixOS + HM module builder)
#   builders/         → mkNixosConfiguration (used directly by flake.nix)
{ lib, ... }:
let
  mkModuleLib = import ./modules/mkModule { inherit lib; };
  shellLib = pkgs: import ./shell { inherit lib pkgs; };
  fsLib = import ./fs.nix { inherit lib; };
  audioLib = import ./audio.nix { inherit lib; };
  hmLib = import ./hm.nix { inherit lib; };
in
{
  # ── Module builder ───────────────────────────────────────────────────────────
  # Primary API: wraps NixOS + Home Manager config under options.my.<name>.enable
  mkModule = mkModuleLib;

  # ── Feature toggles ──────────────────────────────────────────────────────────
  # Transforms userFeatures: { feat = true; } → { feat = { enable = true; }; }
  mapFeatures = import ./features.nix { inherit lib; };

  # ── Home Manager helpers ──────────────────────────────────────────────────────
  # Wraps lib.file.mkOutOfStoreSymlink for bulk symlink declarations
  inherit (hmLib) mkHmSymlinks;

  # ── Shell app builders ────────────────────────────────────────────────────────
  # mkApp: pkgs.writeShellApplication wrapper with __toString for string coercion
  mkApp = pkgs: (shellLib pkgs).mkApp;
  mkShellCompletions = pkgs: (shellLib pkgs).mkShellCompletions;

  # ── Network / WARP helpers ────────────────────────────────────────────────────
  # warpProxyEnv: static socks5h://127.0.0.1:40000 env-var set (no pkgs needed)
  warpProxyEnv = (import ./network { pkgs = null; }).warpProxyEnv;
  mkWarpWaitScript = pkgs: name: (import ./network { inherit pkgs; }).mkWarpWaitScript name;

  # ── Browser addons ────────────────────────────────────────────────────────────
  # Call with { inherit pkgs inputs; } — see lib/browser-addons/default.nix
  browserAddonsFor = args: import ./browser-addons args;

  # ── Filesystem helpers ────────────────────────────────────────────────────────
  # scanPaths: Dendritic auto-import traverser (stops at non-dummy default.nix)
  # getVpnFiles: list WireGuard .conf filenames in a directory
  inherit (fsLib) scanPaths getVpnFiles;

  # ── Audio helpers ─────────────────────────────────────────────────────────────
  # Renders EQ filter attrsets to PipeWire filter-chain string
  inherit (audioLib) mkEqFilterString;
}
