# selfLib — Composed library for nixos-config.
# No logic lives here; each domain has its own focused sub-module.
#
# Sub-module map:
#   features.nix      → mapFeatures (feature-toggle transformer)
#   hm.nix            → mkHmSymlinks (out-of-store symlink helper)
#   fs.nix            → scanPaths, getVpnFiles (filesystem helpers)
#   audio.nix         → mkEqFilterString (PipeWire EQ renderer)
#   shell-check.nix   → isShellEnabled (compositor shell detection helper)
#   shell/            → mkApp, mkShellCompletions (shell app builders)
#   network/          → warpProxyEnv, mkWarpWaitScript (WARP helpers)
#   browser-addons/   → browserAddonsFor (Firefox/Zen/Tor policy builders)
#   modules/mkModule/ → mkModule (unified NixOS + HM module builder)
#   builders/         → mkNixosConfiguration (used directly by flake.nix)
{ lib, ... }:
let
  mkModuleLib = import ./modules/mkModule { inherit lib; };
  nativeAppLib = pkgs: import ./modules/mkNativeApp { inherit lib pkgs; };
  shellLib = pkgs: import ./shell { inherit lib pkgs; };
  fsLib = import ./fs.nix { inherit lib; };
  audioLib = import ./audio.nix { inherit lib; };
  hmLib = import ./hm.nix { inherit lib; };
  shellCheckLib = import ./shell-check.nix { inherit lib; };
  webAppLib = pkgs: import ./webapp.nix { inherit lib pkgs; };
in
{
  # ── Module builder ───────────────────────────────────────────────────────────
  # Primary API: wraps NixOS + Home Manager config under options.my.<name>.enable
  mkModule = mkModuleLib;

  # ── Native App builder & Version Pinning ──────────────────────────────────────
  # Builder universal untuk membungkus biner/arsip (.deb, .tar.*, .pkg.tar.zst, .snap, .AppImage)
  # dengan runtime library host nix-ld, PATH wrapper, dan integrasi desktop.
  mkNativeApp = pkgs: (nativeAppLib pkgs).mkNativeApp;
  appVersions = import ./apps-versions.nix;
  fetchApp = pkgs: name: pkgs.fetchurl (import ./apps-versions.nix).${name};

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
  warpProxyEnv = port: (import ./network { pkgs = null; }).warpProxyEnv port;
  mkWarpWaitScript =
    pkgs: port: name:
    (import ./network { inherit pkgs; }).mkWarpWaitScript port name;

  # ── Browser addons ────────────────────────────────────────────────────────────
  # Call with { inherit pkgs inputs; } — see lib/browser-addons/default.nix
  browserAddonsFor = args: import ./browser-addons args;

  # ── Filesystem helpers ────────────────────────────────────────────────────────
  # scanPaths: Dendritic auto-import traverser (stops at non-dummy default.nix)
  # getVpnFiles: list WireGuard .conf filenames in a directory
  inherit (fsLib) scanPaths getVpnFiles;

  # ── Shell check helpers ──────────────────────────────────────────────────────
  # isShellEnabled: safe osConfig check for shell enable state across compositors
  inherit (shellCheckLib) isShellEnabled;

  # ── Audio helpers ─────────────────────────────────────────────────────────────
  # Renders EQ filter attrsets to PipeWire filter-chain string
  inherit (audioLib) mkEqFilterString;

  # ── WebApp PWA Builder ──────────────────────────────────────────────────────
  # Generates desktop launcher + Chromium wrapper for PWAs
  mkWebApp = pkgs: (webAppLib pkgs).mkWebApp;
}
