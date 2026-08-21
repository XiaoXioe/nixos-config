# Shared hooks and constants reused across all per-distro modules.
# This file is imported as a plain attrset — no `lib` required.
{
  # Essential systemd pre-init hook to prevent permission/mount errors in rootless podman.
  systemdMountHook = "mkdir -p /run/systemd/journal /run/systemd/seats /run/systemd/sessions /run/systemd/users /var/lib/systemd/coredump 2>/dev/null || true";

  # Prevents dpkg/apt from invoking systemd-tmpfiles inside rootless containers.
  debianTmpfilesDivertHook = "(dpkg-divert --local --rename --add /usr/bin/systemd-tmpfiles 2>/dev/null || true) && (ln -sf /bin/true /usr/bin/systemd-tmpfiles 2>/dev/null || true)";
}
