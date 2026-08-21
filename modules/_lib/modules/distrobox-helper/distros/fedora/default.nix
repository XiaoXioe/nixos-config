_:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  # Covers Fedora, RHEL UBI images, CentOS Stream, Rocky Linux, and AlmaLinux.
  name = "fedora";
  detectionPatterns = [
    "fedora"
    "ubi"
    "centos"
    "rocky"
    "alma"
  ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "dnf";
  checkCmd = "dnf";
  installCmd = "dnf install -y --setopt=install_weak_deps=False";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  basePackages = _: [
    "ca-certificates"
    "curl"
    "gnupg2"
    "dejavu-sans-fonts"
    "google-noto-color-emoji-fonts"
    "liberation-sans-fonts"
    "mesa-dri-drivers"
    "mesa-vulkan-drivers"
    "mesa-libGL"
    "pipewire-libs"
    "pulseaudio-libs"
    "alsa-lib"
  ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  preInitHooks = [
    common.systemdMountHook
  ];
}
