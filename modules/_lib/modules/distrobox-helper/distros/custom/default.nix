{ lib }:

{
  # ── Identity ────────────────────────────────────────────────────────────────
  # Custom distro: user-managed image with no automatic base packages or hooks.
  # Never auto-detected — must be set explicitly via `distro = "custom"`.
  name = "custom";
  detectionPatterns = [ ]; # empty: never matched by detectDistro auto-detection

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "unknown";
  checkCmd = null; # null = distrobox-sync skips package sync for this container
  installCmd = null;

  # ── Base packages & hooks ───────────────────────────────────────────────────
  basePackages = _: [ ];
  preInitHooks = [ ];
}
