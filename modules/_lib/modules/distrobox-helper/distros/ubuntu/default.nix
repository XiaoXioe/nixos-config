{ lib }:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  name = "ubuntu";
  detectionPatterns = [ "ubuntu" ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "apt";
  checkCmd = "apt-get";
  installCmd = "apt-get install -y --no-install-recommends";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  # deltaUpdates defaults to false for Ubuntu — debdelta support is unreliable
  # on Ubuntu PPAs and may not be available in all Ubuntu releases.
  basePackages =
    {
      deltaUpdates ? false,
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
  preInitHooks = [
    common.systemdMountHook
    common.debianTmpfilesDivertHook
  ];
}
