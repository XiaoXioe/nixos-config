{ lib }:

# Aggregator for all per-distro modules.
# Each distro lives in its own sub-directory under distros/ and exports:
#   name             : string         — canonical distro key
#   detectionPatterns: [string]       — substrings matched against lowercased image name
#   pkgManager       : string         — bash pkg-manager name (apt/pacman/dnf/apk/zypper/xbps)
#   checkCmd         : string | null  — binary to probe inside container
#   installCmd       : string | null  — full install invocation (packages appended, sudo at call site)
#   basePackages     : { deltaUpdates ? bool } -> [string]
#   preInitHooks     : [string]
# Arch-specific extras (only in distros/arch-linux/):
#   aurBuildPrereqs  : [string]       — makepkg build dependencies
#   mkAurBuildHook   : string -> string — generates single-line AUR build command
let
  allDistros = map (f: import f { inherit lib; }) [
    ./distros/arch-linux
    ./distros/debian
    ./distros/ubuntu
    ./distros/fedora
    ./distros/alpine
    ./distros/opensuse
    ./distros/void
    ./distros/custom
  ];

  # Lookup table: distro-name → distro-module attrset.
  distroTable = lib.listToAttrs (map (d: lib.nameValuePair d.name d) allDistros);

  # Detect distro from OCI image name string (case-insensitive substring match).
  # Returns "debian" for null/empty images (system-wide default in this setup).
  detectDistro =
    image:
    if image == null || image == "" then
      "debian"
    else
      let
        lowerImage = lib.toLower image;
        candidates = lib.filter (d: d.detectionPatterns != [ ]) allDistros;
        found = lib.findFirst (
          d: lib.any (p: lib.hasInfix p lowerImage) d.detectionPatterns
        ) null candidates;
      in
      if found != null then found.name else "custom";

  # Detection rules table consumed by mkDetectPkgManagerBash for codegen.
  distroDetectionRules = map (d: {
    patterns = d.detectionPatterns;
    distro = d.name;
    pkgMgr = d.pkgManager;
  }) (lib.filter (d: d.detectionPatterns != [ ]) allDistros);

in
{
  inherit detectDistro distroDetectionRules;

  # Returns the list of base packages for a given distro key.
  getDistroBasePackages =
    {
      distro,
      deltaUpdates ? true,
    }:
    let
      d = distroTable.${distro} or distroTable.custom;
    in
    d.basePackages { inherit deltaUpdates; };

  # Returns the list of pre-init hook strings for a given distro key.
  getDistroPreInitHooks =
    { distro }:
    let
      d = distroTable.${distro} or distroTable.custom;
    in
    d.preInitHooks or [ ];

  # Returns { check, cmd } for distrobox-sync package installation, or null
  # when the distro has no known package manager (e.g. custom).
  # `cmd` is the full install invocation; packages appended as trailing args.
  # Sudo is applied at the call site.
  getDistroInstallCmd =
    { distro }:
    let
      d = distroTable.${distro} or distroTable.custom;
    in
    if d ? checkCmd && d.checkCmd != null && d ? installCmd && d.installCmd != null then
      {
        check = d.checkCmd;
        cmd = d.installCmd;
      }
    else
      null;

  # Returns { mkAurBuildHook, aurBuildPrereqs } for distros that support AUR
  # (currently only Arch Linux), or null for all other distros.
  # Keeps AUR-specific logic inside the arch-linux module — not here.
  getDistroAurSupport =
    { distro }:
    let
      d = distroTable.${distro} or distroTable.custom;
    in
    if d ? mkAurBuildHook then { inherit (d) mkAurBuildHook aurBuildPrereqs; } else null;

  # Generates bash detect_pkg_manager() from the distroDetectionRules table
  # so that distrobox-pkg.nix never duplicates the detection logic in bash.
  # Adding a new distro only requires editing its distros/<name>/default.nix.
  mkDetectPkgManagerBash =
    rules:
    let
      cases = lib.concatStringsSep "\n  " (
        map (
          rule:
          let
            conds = map (p: "[[ \"$lower_image\" == *\"${p}\"* ]]") rule.patterns;
          in
          "if ${lib.concatStringsSep " || " conds}; then echo \"${rule.pkgMgr}\"; return; fi"
        ) rules
      );
    in
    ''
      detect_pkg_manager() {
        local lower_image
        lower_image="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
        ${cases}
        echo "unknown"
      }
    '';
}
