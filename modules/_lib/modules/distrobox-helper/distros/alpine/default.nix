_:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  name = "alpine";
  detectionPatterns = [ "alpine" ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "apk";
  checkCmd = "apk";
  installCmd = "apk add --no-cache";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  basePackages = _: [
    "ca-certificates"
    "curl"
    "gnupg"
    "ttf-dejavu"
    "font-noto-emoji"
    "ttf-liberation"
    "mesa-dri-gallium"
    "mesa-vulkan-intel"
    "mesa-vulkan-ati"
    "pipewire"
    "libpulse"
    "alsa-lib"
  ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  preInitHooks = [
    common.systemdMountHook
  ];
}
