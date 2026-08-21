# selfLib.distrobox — Ergonomic distroboxCfg builder helpers.
#
# Each helper auto-sets distro-specific defaults and accepts Nix packages in
# `packages`, automatically extracting:
#   - Container install names (strings for distrobox-assemble)
#   - `binName` (from pkg.meta.mainProgram or pkg.pname)
#   - Native fallback `package` (from first Nix pkg in list)
#
# Supported Usage Forms:
#   1. Curried with custom container name:
#      selfLib.distrobox.arch "aria2" {
#        packages = with pkgs; [ aria2 ];
#        chaoticAur = true;
#      }
#
#   2. Attrset with explicit `name`:
#      selfLib.distrobox.debian {
#        name = "firefox";
#        packages = with pkgs; [ firefox-esr ];
#      }
#
#   3. Attrset with default container name:
#      selfLib.distrobox.arch {
#        packages = with pkgs; [ yt-dlp ffmpeg ];
#      }
#      # → { arch = { ... }; }
#
# Mixed string + Nix packages are supported:
#   packages = with pkgs; [ yt-dlp ffmpeg ] ++ [ "atomicparsley" "python-mutagen" ];
#
# Fields handled by the helper (should not be set manually):
#   image   — auto from distro default (can override if needed)
#   distro  — always set from helper name
#   binName — auto from first Nix pkg meta.mainProgram (can override explicitly)
#   package — auto from first Nix pkg (native fallback; can override explicitly)
{ lib }:

let
  # ── Default OCI images per distro ───────────────────────────────────────────
  defaultImages = {
    arch = "docker.io/library/archlinux:latest";
    debian = null; # uses global programs.distrobox.settings.container_image_default
    ubuntu = "docker.io/library/ubuntu:latest";
    fedora = "docker.io/library/fedora:latest";
    alpine = "docker.io/library/alpine:latest";
    opensuse = "registry.opensuse.org/opensuse/tumbleweed:latest";
    void = "ghcr.io/void-linux/void-linux:latest";
  };

  # ── Default container key per distro (used when `name` is not set) ─────────
  defaultNames = {
    arch = "arch";
    debian = "debian";
    ubuntu = "ubuntu";
    fedora = "fedora";
    alpine = "alpine";
    opensuse = "opensuse";
    void = "void";
  };

  # ── Package resolution helpers ───────────────────────────────────────────────

  # Resolves a single entry to an install name string.
  # Nix derivations → pname (nama paket untuk package manager di dalam container).
  # meta.mainProgram is intentionally NOT used here — that's the binary name, not the package name.
  # Example: pkgs.aria2 → "aria2" (pacman install name), not "aria2c" (binary name).
  toInstallName = pkg: if builtins.isString pkg then pkg else pkg.pname or (lib.getName pkg);

  # Extracts binary name from a Nix derivation (meta.mainProgram > pname); null for strings or null.
  getBinName =
    pkg:
    if pkg == null || builtins.isString pkg then
      null
    else
      pkg.meta.mainProgram or pkg.pname or (lib.getName pkg);

  # ── Core builder ─────────────────────────────────────────────────────────────
  mkDistroboxContainer =
    distro: attrs:
    let
      containerName = attrs.name or (defaultNames.${distro} or distro);

      rawPackages = attrs.packages or [ ];

      # Collect Nix derivations for auto-derive logic
      nixPkgsInList = lib.filter lib.isDerivation rawPackages;

      # Resolve all package entries to install names consumed by distrobox-assemble
      resolvedPkgNames = map toInstallName rawPackages;

      # ── Auto-derive native fallback package ──────────────────────────────────
      # Skip if user already provided package / nativePkgs / native explicitly.
      hasExplicitNative = attrs ? package || attrs ? nativePkgs || attrs ? native;
      autoPkg =
        if hasExplicitNative then
          null
        else if nixPkgsInList != [ ] then
          builtins.head nixPkgsInList
        else
          null;

      # ── Auto-derive binName ──────────────────────────────────────────────────
      # Priority: explicit binName > first Nix pkg meta > package field meta
      hasExplicitBinName = attrs ? binName && attrs.binName != null;
      autoBinName =
        if hasExplicitBinName then
          attrs.binName
        else if nixPkgsInList != [ ] then
          getBinName (builtins.head nixPkgsInList)
        else if attrs ? package then
          getBinName attrs.package
        else
          null;

      # ── Compose final container value ────────────────────────────────────────
      # 1. Start from user attrs, stripping builder-only fields.
      # 2. Override/set distro, image (with default), resolved packages.
      # 3. Apply auto-derived binName (lowest priority: only when not explicit).
      # 4. Apply auto-derived native fallback package.
      containerVal =
        (builtins.removeAttrs attrs [
          "name" # builder-only: becomes the attrset key
          "packages" # builder-only: replaced by resolvedPkgNames
          "binName" # handled via autoBinName below
          "distro" # always set from helper name, never from user
        ])
        // {
          inherit distro;
          image = attrs.image or (defaultImages.${distro} or null);
          packages = resolvedPkgNames;
        }
        // (lib.optionalAttrs (autoBinName != null) { binName = autoBinName; })
        // (lib.optionalAttrs (autoPkg != null) { package = autoPkg; });
    in
    {
      ${containerName} = containerVal;
    };

  # Polymorphic helper: allows both `selfLib.distrobox.arch "customName" { ... }`
  # and `selfLib.distrobox.arch { name = "customName"; ... }`.
  mkDistroboxHelper =
    distro: nameOrAttrs:
    if builtins.isString nameOrAttrs then
      (attrs: mkDistroboxContainer distro (attrs // { name = nameOrAttrs; }))
    else
      mkDistroboxContainer distro nameOrAttrs;
in
# Expose polymorphic helper per supported distro, e.g. selfLib.distrobox.arch { ... } or selfLib.distrobox.arch "name" { ... }
lib.mapAttrs (_distro: _: mkDistroboxHelper _distro) defaultImages
