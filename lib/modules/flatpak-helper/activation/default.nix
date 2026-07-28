{ lib, ... }:

let
  utils = import ../utils { inherit lib; };
in
{
  mkFlatpakActivationScripts =
    { ctx, useFlatpak }:
    hmLib:
    let
      flatpakCfg = ctx.flatpakCfg;
    in
    lib.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          let
            flatpakIdSafe = lib.replaceStrings [ "." ] [ "-" ] appId;
            flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);

            pruneCmds = ''
              # Prune old symlinks using manifest to avoid collateral damage
              manifest="$HOME/.var/app/${appId}/.nix-managed-symlinks"
              if [ -f "$manifest" ]; then
                while IFS= read -r old_guest; do
                  ${
                    if flatpakSymlinks == [ ] then
                      ''
                        is_active=0
                      ''
                    else
                      ''
                        case "$old_guest" in
                          ${
                            lib.concatMapStringsSep "|" (s: "\"${utils.sanitizePath s.guest}\"") flatpakSymlinks
                          }) is_active=1 ;;
                          *) is_active=0 ;;
                        esac
                      ''
                  }
                  if [ "$is_active" -eq 0 ] && [ -n "$old_guest" ]; then
                    echo "Pruning stale Flatpak symlink: $old_guest"
                    rm -f "$HOME/.var/app/${appId}/$old_guest"
                  fi
                done < "$manifest"
              fi

              # Update manifest
              mkdir -p "$HOME/.var/app/${appId}"
              > "$manifest"
              ${lib.concatMapStringsSep "\n              " (s: ''
                echo "${utils.sanitizePath s.guest}" >> "$manifest"
              '') flatpakSymlinks}
            '';

            symlinkCmds = lib.concatMapStringsSep "\n" (
              s:
              let
                guestPath = utils.sanitizePath s.guest;
              in
              if guestPath == ".zen" || guestPath == ".mozilla" then
                builtins.abort "Sandbox escape: guest path cannot be ${s.guest}"
              else
                ''
                  # Ensure target directories exist on host
                  mkdir -p "$(dirname "$HOME/${s.host}")"
                  if [ ! -e "$HOME/${s.host}" ]; then
                    mkdir -p "$HOME/${s.host}"
                  fi

                  # If guest target exists (file or directory) and is not a symlink, backup it to prevent nesting/conflicts
                  if [ -e "$HOME/.var/app/${appId}/${guestPath}" ] && [ ! -L "$HOME/.var/app/${appId}/${guestPath}" ]; then
                    mv "$HOME/.var/app/${appId}/${guestPath}" "$HOME/.var/app/${appId}/${guestPath}.bak"
                  fi

                  mkdir -p "$(dirname "$HOME/.var/app/${appId}/${guestPath}")"
                  # Create direct out-of-store symlink
                  ln -sfn "$HOME/${s.host}" "$HOME/.var/app/${appId}/${guestPath}"
                ''
            ) flatpakSymlinks;

            flatpakFlags = appVal.flags or { };
            flagsFile =
              if flatpakFlags ? file && flatpakFlags.file != null then
                utils.sanitizePath flatpakFlags.file
              else
                null;
            flagsCmds =
              if flagsFile != null && flatpakFlags ? text && flatpakFlags.text != "" then
                ''
                  mkdir -p "$(dirname "$HOME/.var/app/${appId}/${flagsFile}")"
                  cat << 'EOF' > "$HOME/.var/app/${appId}/${flagsFile}"
                  ${flatpakFlags.text}
                  EOF
                ''
              else
                "";

            declaredEnvKeys = builtins.attrNames (appVal.overrides.Environment or { });
            cleanEnvCmds =
              let
                casePattern = if declaredEnvKeys == [ ] then "" else lib.concatStringsSep "|" declaredEnvKeys;
              in
              ''
                # Auto-cleanup stale user flatpak environment overrides not defined in Nix configuration
                override_file="$HOME/.local/share/flatpak/overrides/${appId}"
                if [ -f "$override_file" ]; then
                  current_envs=$(sed -n '/^\[Environment\]/,/^\[/p' "$override_file" | grep '=' | cut -d'=' -f1 || true)
                  for env_key in $current_envs; do
                    ${
                      if declaredEnvKeys == [ ] then
                        ''
                          # No declared env keys — all overrides are stale
                          is_declared=0
                        ''
                      else
                        ''
                          case "$env_key" in
                            ${casePattern}) is_declared=1 ;;
                            *) is_declared=0 ;;
                          esac
                        ''
                    }
                    if [ "$is_declared" -eq 0 ] && [ -n "$env_key" ]; then
                      echo "Auto-purging stale Flatpak environment override for ${appId}: $env_key"
                      ${ctx.pkgs.flatpak}/bin/flatpak override --user --unset-env="$env_key" "${appId}" 2>/dev/null || true
                    fi
                  done
                fi
                true
              '';
          in
          lib.optionals (useFlatpak ctx appId) [
            (lib.nameValuePair "setup-flatpak-${flatpakIdSafe}" (
              hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
                ${pruneCmds}
                ${symlinkCmds}
                ${flagsCmds}
                ${cleanEnvCmds}
              ''
            ))
          ]
        ) flatpakCfg
      )
    );
}
