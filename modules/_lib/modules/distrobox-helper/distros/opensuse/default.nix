{ lib }:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  # Covers openSUSE Tumbleweed (rolling) and openSUSE Leap (stable).
  name = "opensuse";
  detectionPatterns = [
    "opensuse"
    "tumbleweed"
    "leap"
  ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "zypper";
  checkCmd = "zypper";
  installCmd = "zypper install -y --no-recommends";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  basePackages = _: [
    "ca-certificates"
    "curl"
    "gpg2"
    "dejavu-fonts"
    "noto-coloremoji-fonts"
    "liberation-fonts"
    "Mesa"
    "Mesa-dri"
    "Mesa-vulkan-device-select"
    "libpipewire-0_3-0"
    "libpulse0"
    "libasound2"
  ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  preInitHooks = [
    common.systemdMountHook
  ];
}
