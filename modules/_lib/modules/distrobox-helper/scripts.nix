{ lib }:

let
  distrosModule = import ./distros.nix { inherit lib; };
in
{
  # ── Distrobox Prune Script ──────────────────────────────────────────────────
  # Scans existing containers via `distrobox list` and removes those that are
  # not in declaredContainers list.
  mkDistroboxPruneScript =
    { pkgs, declaredContainers }:
    pkgs.writeShellScriptBin "distrobox-prune" ''
      set -euo pipefail
      declared_containers=( ${lib.concatStringsSep " " (map (c: "\"${c}\"") declaredContainers)} )

      echo "==> Active declared Distrobox containers: ''${declared_containers[*]:-(none)}"

      existing_containers=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2}' || true)

      if [ -z "$existing_containers" ]; then
        echo "No Distrobox containers found."
        exit 0
      fi

      for c in $existing_containers; do
        keep=false
        for d in "''${declared_containers[@]}"; do
          if [ "$c" = "$d" ]; then
            keep=true
            break
          fi
        done
        if [ "$keep" = false ]; then
          echo "==> Pruning unmanaged/orphan Distrobox container: $c"
          ${pkgs.distrobox}/bin/distrobox rm -f "$c" 2>/dev/null || true
        fi
      done
    '';

  # ── Distrobox Auto-Update Script ────────────────────────────────────────────
  # Upgrades official packages via `distrobox upgrade --all` and detects Arch
  # containers to update foreign (AUR) packages via makepkg as non-root user.
  mkDistroboxAutoUpdateScript =
    {
      pkgs,
      pruneOrphanContainers ? false,
      distroboxPruneScript ? null,
    }:
    pkgs.writeShellScript "distrobox-autoupdate" ''
      set -euo pipefail
      echo "==> Upgrading Distrobox containers (official packages)..."
      ${pkgs.distrobox}/bin/distrobox upgrade --all || true

      # Check and update AUR packages on Arch Linux containers
      existing_containers=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2}' || true)
      for c in $existing_containers; do
        if ${pkgs.distrobox}/bin/distrobox enter "$c" -- sh -c "command -v pacman >/dev/null 2>&1"; then
          echo "==> [distrobox-autoupdate] Checking AUR updates for container '$c'..."
          ${pkgs.distrobox}/bin/distrobox enter "$c" -- bash -c '
            _buser=$(id -un 1000 2>/dev/null || whoami)
            aur_pkgs=$(pacman -Qm -q 2>/dev/null || true)
            if [ -n "$aur_pkgs" ]; then
              for pkg in $aur_pkgs; do
                echo "==> [distrobox-autoupdate] Checking AUR package: $pkg..."
                _aur_tmp=$(mktemp -d /tmp/aur-update-"$pkg"-XXXXXX)
                chown -R "$_buser" "$_aur_tmp"
                if sudo -u "$_buser" git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$_aur_tmp" 2>/dev/null; then
                  (cd "$_aur_tmp" && sudo -u "$_buser" makepkg -si --noconfirm --skippgpcheck --needed) || true
                fi
                rm -rf "$_aur_tmp"
              done
            fi
          ' || true
        fi
      done

      ${lib.optionalString (pruneOrphanContainers && distroboxPruneScript != null) ''
        echo "==> Pruning orphan containers..."
        ${distroboxPruneScript}/bin/distrobox-prune
      ''}
    '';

  # ── Distrobox Sync Script ───────────────────────────────────────────────────
  # Synchronizes packages, pre-init hooks (with sudo), and init hooks for all
  # merged declarative containers.
  mkDistroboxSyncScript =
    {
      pkgs,
      mergedContainerMap,
      mergedDistroboxContainers,
    }:
    pkgs.writeShellScriptBin "distrobox-sync" ''
      set -euo pipefail

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          cId: cDef:
          let
            rawCfg = mergedContainerMap.${cId};
            targetDistro =
              if rawCfg.distro != "auto" then rawCfg.distro else distrosModule.detectDistro rawCfg.image;
            installInfo = distrosModule.getDistroInstallCmd { distro = targetDistro; };

            hasPkgs = cDef ? additional_packages && cDef.additional_packages != "" && installInfo != null;
            hasPreHooks = cDef ? pre_init_hooks && cDef.pre_init_hooks != [ ];
            hasHooks = cDef ? init_hooks && cDef.init_hooks != [ ];

            preHooksCmd = lib.optionalString hasPreHooks (
              lib.concatStringsSep "\n" (map (h: "  " + h) cDef.pre_init_hooks)
            );
            preHooksScript = pkgs.writeShellScript "distrobox-pre-hooks-${cId}" ''
              set -euo pipefail
              ${preHooksCmd}
            '';

            hooksCmd = lib.optionalString hasHooks (
              lib.concatStringsSep "\n" (map (h: "  " + h) cDef.init_hooks)
            );
            hooksScript = pkgs.writeShellScript "distrobox-hooks-${cId}" ''
              set -euo pipefail
              ${hooksCmd}
            '';
          in
          ''
            echo "==> [distrobox-sync] Synchronizing container: ${cId} (${targetDistro})"
            if ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- true 2>/dev/null; then
              ${lib.optionalString hasPreHooks ''
                echo "==> [distrobox-sync] Running pre-init hooks for ${cId}..."
                ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- sudo ${preHooksScript} || true
              ''}
              ${lib.optionalString hasPkgs ''
                if ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- sh -c "command -v ${installInfo.check} >/dev/null 2>&1"; then
                  echo "==> [distrobox-sync] Installing packages for ${cId} (${installInfo.cmd})..."
                  ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- sudo ${installInfo.cmd} ${cDef.additional_packages} || true
                fi
              ''}
              ${lib.optionalString hasHooks ''
                echo "==> [distrobox-sync] Running init hooks for ${cId}..."
                ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- ${hooksScript} || true
              ''}
            fi
          ''
        ) mergedDistroboxContainers
      )}
    '';
}
