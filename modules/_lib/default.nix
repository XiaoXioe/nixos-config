# selfLib — Composed library for nixos-config.
# No logic lives here; each domain has its own focused sub-module.
#
# Sub-module map:
#   features.nix      → mapFeatures (feature-toggle transformer)
#   hm.nix            → mkHmSymlinks (out-of-store symlink helper)
#   fs.nix            → scanPaths, getVpnFiles (filesystem helpers)
#   audio.nix         → mkEqFilterString (PipeWire EQ renderer)
#   shell-check.nix   → isShellEnabled (compositor shell detection helper)
#   webapp.nix        → mkWebApp (PWA desktop app builder)
#   shell/            → mkApp, mkShellCompletions (shell app builders)
#   network/          → warpProxyEnv, mkWarpWaitScript (WARP helpers)
#   browser-addons/   → browserAddonsFor (Firefox/Zen/Tor policy builders)
#   mk-module/        → mkModule (unified NixOS + HM module builder)
#   native-app/       → mkNativeApp, fetchApp, fetchUnpackedApp, allAppSources, activeAppSources
#   cache/            → fetchFromNixCache, fetchCachePinned (Nix cache ingestion)
#   builders/         → mkNixosConfiguration (used directly by flake.nix)
{ lib, ... }:
let
  mkModuleLib = import ./mk-module { inherit lib; };
  nativeAppLib = import ./native-app { inherit lib; };
  shellLib = import ./shell { inherit lib; };
  networkLib = import ./network { };
  nixCacheLib = import ./cache { inherit lib; };

  fsLib = import ./fs.nix { inherit lib; };
  audioLib = import ./audio.nix { inherit lib; };
  hmLib = import ./hm.nix { inherit lib; };
  shellCheckLib = import ./shell-check.nix { inherit lib; };
  webAppLib = pkgs: import ./webapp.nix { inherit lib pkgs; };

  # Single import of version registries — avoids redundant AST parsing
  appVersionsData = import ./apps-versions.nix;
  cachePinsData = import ./cache-pins.nix;
in
{
  # ── Module builder ───────────────────────────────────────────────────────────
  # Primary API: wraps NixOS + Home Manager config under options.my.<name>.enable
  mkModule = mkModuleLib;

  # ── Native App builder & Version Pinning ──────────────────────────────────────
  # Builder universal untuk membungkus biner/arsip (.deb, .tar.*, .pkg.tar.zst, .snap, .AppImage)
  # dengan runtime library host nix-ld, PATH wrapper, dan integrasi desktop.
  mkNativeApp = pkgs: (nativeAppLib pkgs).mkNativeApp;
  fetchUnpacked = pkgs: (nativeAppLib pkgs).fetchUnpacked;
  appVersions = appVersionsData;
  fetchApp = pkgs: (nativeAppLib pkgs).fetchApp;
  fetchUnpackedApp = pkgs: (nativeAppLib pkgs).fetchUnpackedApp;
  allAppSources = pkgs: (nativeAppLib pkgs).allAppSources;
  activeAppSources = { pkgs, config }: (nativeAppLib pkgs).activeAppSources config;

  # ── Feature toggles ──────────────────────────────────────────────────────────
  # Transforms userFeatures: { feat = true; } → { feat = { enable = true; }; }
  mapFeatures = import ./features.nix { inherit lib; };

  # ── Home Manager helpers ──────────────────────────────────────────────────────
  # Wraps lib.file.mkOutOfStoreSymlink for bulk symlink declarations
  inherit (hmLib) mkHmSymlinks;

  # ── Shell app builders ────────────────────────────────────────────────────────
  # mkApp: pkgs.writeShellApplication wrapper with __toString for string coercion
  inherit (shellLib) mkApp mkShellCompletions;

  # ── Network / WARP helpers ────────────────────────────────────────────────────
  inherit (networkLib) warpProxyEnv mkWarpWaitScript;

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

  # ── Nix Binary Cache Direct Ingestion ────────────────────────────────────
  inherit (nixCacheLib) fetchFromNixCache;
  cachePins = cachePinsData;
  fetchCachePinned = nixCacheLib.fetchCachePinned cachePinsData;
}
