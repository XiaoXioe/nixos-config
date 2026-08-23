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
  # Single import of version registry — avoids 4× redundant AST parsing
  appVersionsData = import ./apps-versions.nix;
  # Nix Binary Cache pin registry — store paths dari Hydra/cache.nixos.org
  cachePinsData = import ./cache-pins.nix;
  # fetchNixCache lib — pure builtins.fetchClosure, tidak butuh pkgs
  nixCacheLib = import ./modules/fetchNixCache { inherit lib; };
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
  fetchApp = pkgs: name: pkgs.fetchurl appVersionsData.${name};
  fetchUnpackedApp =
    pkgs: name:
    let
      info = appVersionsData.${name};
      hash = info.unpackedHash or info.hash;
    in
    (nativeAppLib pkgs).fetchUnpacked (
      info
      // {
        pname = name;
        inherit hash;
      }
    );
  allAppSources =
    pkgs:
    pkgs.linkFarm "native-app-sources" (
      lib.mapAttrsToList (name: info: {
        name = "${name}-${info.version}";
        path = pkgs.fetchurl {
          inherit (info) url hash;
        };
      }) appVersionsData
    );
  activeAppSources =
    { pkgs, config }:
    let
      # Alias jika nama modul sedikit berbeda dengan nama key di apps-versions.nix
      aliases = {
        zed = "zeditor";
        betterbird = "thunderbird";
        ppsspp = "emulators";
        pcsx2 = "emulators";
        retroarch = "emulators";
        retroarch-cores = "emulators";
        tdl = "downloader";
      };

      # Cek apakah modul dengan nama tertentu aktif di config.my tree.
      # Melakukan traversal hingga kedalaman 3 untuk mendukung nested module paths.
      isModuleEnabled =
        name:
        let
          targetKey = aliases.${name} or name;

          checkAtDepth =
            depth: set:
            if depth > 3 || !builtins.isAttrs set then
              false
            else if set ? ${targetKey} && builtins.isAttrs set.${targetKey} && set.${targetKey} ? enable then
              set.${targetKey}.enable == true
            else
              lib.any (child: checkAtDepth (depth + 1) child) (
                lib.filter (v: builtins.isAttrs v && !(v ? _type)) (builtins.attrValues set)
              );
        in
        checkAtDepth 0 (config.my.apps or { }) || checkAtDepth 0 (config.my.security or { });

      activeEntries = lib.filterAttrs (name: _: isModuleEnabled name) appVersionsData;
    in
    pkgs.linkFarm "native-app-sources" (
      lib.mapAttrsToList (name: info: {
        name = "${name}-${info.version}";
        path = pkgs.fetchurl {
          inherit (info) url hash;
        };
      }) activeEntries
    );

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

  # ── Nix Binary Cache Direct Ingestion ────────────────────────────────────
  # Fetch binary langsung dari cache.nixos.org via builtins.fetchClosure.
  # Tidak ada pkgs dependency — pure builtins, zero nixpkgs closure overhead.
  # Requires: nix.settings.experimental-features includes "fetch-closure"
  #
  # fetchFromNixCache { storePath, ?fromStore, ... } → store path string
  # cachePins         → attrset dari cache-pins.nix (registry semua pins)
  # fetchCachePinned  → name → store path (shorthand via registry)
  #
  # Contoh:
  #   environment.systemPackages = [ (selfLib.fetchCachePinned "rclone") ];
  inherit (nixCacheLib) fetchFromNixCache;
  cachePins = cachePinsData;
  fetchCachePinned = nixCacheLib.fetchCachePinned cachePinsData;
}
