{ lib }:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  name = "arch";
  detectionPatterns = [ "arch" ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "pacman";
  checkCmd = "pacman";
  # -Sy: sync database before installing so stale cached versions are not used.
  # --needed: skip reinstall if already at the latest version (idempotent).
  installCmd = "pacman -Sy --needed --noconfirm";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  basePackages = _: [
    "ca-certificates"
    "curl"
    "gnupg"
    "ttf-dejavu"
    "noto-fonts-emoji"
    "ttf-liberation"
    "mesa"
    "vulkan-intel"
    "vulkan-radeon"
    "libpipewire"
    "libpulse"
    "alsa-lib"
  ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  preInitHooks = [
    common.systemdMountHook
    "pacman-key --init 2>/dev/null || true"
    "pacman-key --populate archlinux 2>/dev/null || true"
    "rm -f /var/lib/pacman/db.lck 2>/dev/null || true"
  ];

  # ── AUR support ─────────────────────────────────────────────────────────────
  # Build-time prerequisites that must be installed before any AUR package can
  # be compiled with makepkg inside an Arch container.
  aurBuildPrereqs = [
    "base-devel"
    "git"
    "python"
    "python-setuptools"
    "python-build"
    "python-installer"
    "python-wheel"
    "python-requests"
    "python-urllib3"
  ];

  # Generates a single-line bash command that clones and builds one AUR package
  # via makepkg, handling both root (delegates to uid-1000 builder user) and
  # non-root execution contexts.
  # Must produce a single-line string — distrobox.ini init_hooks entries are
  # single lines. Semicolons separate if/then/else branches instead of newlines.
  mkAurBuildHook =
    pkg:
    let
      rootBranch = lib.concatStringsSep "; " [
        "_buser=$(id -un 1000 2>/dev/null || whoami)"
        "_aur_tmp=$(mktemp -d /tmp/aur-${pkg}-XXXXXX)"
        "chown -R \"$_buser\" \"$_aur_tmp\""
        "(sudo -u \"$_buser\" gpg --recv-keys 5680CA389D365A88 2>/dev/null || true)"
        "sudo -u \"$_buser\" git clone --depth 1 https://aur.archlinux.org/${pkg}.git \"$_aur_tmp\""
        "(cd \"$_aur_tmp\" && sudo -u \"$_buser\" makepkg -si --noconfirm --skippgpcheck) || echo \"==> [WARN] AUR build failed for ${pkg}\""
        "rm -rf \"$_aur_tmp\""
      ];
      nonRootBranch = lib.concatStringsSep "; " [
        "_aur_tmp=$(mktemp -d /tmp/aur-${pkg}-XXXXXX)"
        "(gpg --recv-keys 5680CA389D365A88 2>/dev/null || true)"
        "git clone --depth 1 https://aur.archlinux.org/${pkg}.git \"$_aur_tmp\""
        "(cd \"$_aur_tmp\" && makepkg -si --noconfirm --skippgpcheck) || echo \"==> [WARN] AUR build failed for ${pkg}\""
        "rm -rf \"$_aur_tmp\""
      ];
    in
    "if ! command -v ${pkg} >/dev/null 2>&1 && ! pacman -Qq ${pkg} >/dev/null 2>&1; then if [ \"$(id -u)\" -eq 0 ]; then ${rootBranch}; else ${nonRootBranch}; fi; fi";
}
