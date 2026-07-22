{ lib, ... }:

let
  utils = import ./utils.nix { inherit lib; };
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
                  is_active=0
                  ${lib.concatMapStringsSep "\n                  " (s: ''
                    if [ "$old_guest" = "${utils.sanitizePath s.guest}" ]; then is_active=1; fi
                  '') flatpakSymlinks}
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
          in
          lib.optionals (useFlatpak ctx appId) [
            (lib.nameValuePair "setup-flatpak-${flatpakIdSafe}" (
              hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
                ${pruneCmds}
                ${symlinkCmds}
                ${flagsCmds}
              ''
            ))
          ]
        ) flatpakCfg
      )
    );
}
