{ lib }:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  name = "debian";
  detectionPatterns = [ "debian" ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "apt";
  checkCmd = "apt-get";
  installCmd = "apt-get install -y --no-install-recommends";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  # deltaUpdates: enables debdelta for bandwidth-efficient incremental upgrades.
  basePackages =
    {
      deltaUpdates ? true,
    }:
    [
      "ca-certificates"
      "curl"
      "gnupg"
      "fonts-dejavu"
      "fonts-noto-color-emoji"
      "fonts-liberation"
      "libgl1-mesa-dri"
      "libgl1"
      "libglx-mesa0"
      "mesa-vulkan-drivers"
      "libpipewire-0.3-0"
      "libpulse0"
      "libasound2t64"
    ]
    ++ lib.optionals deltaUpdates [ "debdelta" ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  # debianTmpfilesDivertHook: prevents dpkg/apt from calling systemd-tmpfiles
  # inside rootless containers (would fail with permission errors).
  preInitHooks = [
    common.systemdMountHook
    common.debianTmpfilesDivertHook
  ];
}
