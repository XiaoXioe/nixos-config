{ lib, ... }:

# Helper functions for processing flatpakCfg inside mkModule
let
  splitName = name: lib.splitString "." name;
in
{
  # Generates the Flatpak-related options for options.my.<name>
  mkFlatpakOptions =
    {
      name,
      flatpakCfg,
      options,
      config,
      singleAppInfo,
    }:
    let
      optionPath = splitName name;
      isSingleApp = singleAppInfo.isSingleApp;
      singleAppId = singleAppInfo.singleAppId;
    in
    lib.optionalAttrs (flatpakCfg != { } && !isSingleApp) {
      flatpaks = lib.mapAttrs (appId: appVal: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable ${appId}.";
        };
        flatpak = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default =
              if (options ? flatpak && options.flatpak ? enable) then
                lib.getAttrFromPath (
                  optionPath
                  ++ [
                    "flatpak"
                    "enable"
                  ]
                ) config.my
              else
                appVal.enable or true;
            description = "Whether to use Flatpak for ${appId} instead of the native package.";
          };
        };
      }) flatpakCfg;
    }
    // lib.optionalAttrs (flatpakCfg != { } && isSingleApp) {
      flatpak = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = flatpakCfg.${singleAppId}.enable or true;
          description = "Whether to use Flatpak for ${singleAppId} instead of the native package.";
        };
      };
    };

  # Main runner to compute all configurations
  mkFlatpakConfigs =
    {
      name,
      flatpakCfg,
      options,
      config,
      pkgs,
      enableState,
      singleAppInfo,
    }:
    let
      optionPath = splitName name;
      isSingleApp = singleAppInfo.isSingleApp;
      singleAppId = singleAppInfo.singleAppId;

      getNativePkg =
        appVal:
        let
          nativePkg = appVal.nativePkgs or (appVal.native.package or (appVal.package or null));
          nativePackages =
            if nativePkg == null then [ ] else (if builtins.isList nativePkg then nativePkg else [ nativePkg ]);
          realNativePkg = if nativePackages != [ ] then builtins.elemAt nativePackages 0 else null;
        in
        {
          inherit nativePackages realNativePkg;
        };

      # Helper to check if a specific app is enabled
      isAppEnabled =
        appId:
        if isSingleApp && appId == singleAppId then
          enableState
        else
          let
            appOptPath = optionPath ++ [
              "flatpaks"
              appId
              "enable"
            ];
          in
          if lib.hasAttrByPath appOptPath config.my then lib.getAttrFromPath appOptPath config.my else true;

      # Helper to check if a specific flatpak app is using Flatpak
      useFlatpak =
        appId:
        let
          appVal = flatpakCfg.${appId};
          appOptPath =
            if isSingleApp && appId == singleAppId then
              optionPath
              ++ [
                "flatpak"
                "enable"
              ]
            else
              optionPath
              ++ [
                "flatpaks"
                appId
                "flatpak"
                "enable"
              ];
        in
        isAppEnabled appId
        && (
          if lib.hasAttrByPath appOptPath config.my then
            lib.getAttrFromPath appOptPath config.my
          else
            appVal.enable or true
        );

      # Collect all flatpaks to install
      flatpakPackages = lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          lib.optionals (useFlatpak appId) [
            (
              if appVal ? bundle then
                {
                  inherit appId;
                  inherit (appVal) bundle sha256;
                }
              else
                appId
            )
          ]
        ) flatpakCfg
      );

      # Collect overrides for enabled flatpaks
      flatpakOverrides = lib.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            appId: appVal:
            lib.optionals (useFlatpak appId) [
              (
                let
                  flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);
                  symlinkFilesystems = map (s: "/home/${config.my.user.name}/${s.host}") flatpakSymlinks;
                  baseFilesystems = [ "/nix/store:ro" ] ++ symlinkFilesystems;
                  configuredFilesystems = appVal.overrides.Context.filesystems or [ ];
                  finalFilesystems = lib.unique (baseFilesystems ++ configuredFilesystems);
                in
                lib.nameValuePair appId (
                  lib.recursiveUpdate (appVal.overrides or { }) {
                    Context.filesystems = finalFilesystems;
                  }
                )
              )
            ]
          ) flatpakCfg
        )
      );

      # Home Manager activation script for each enabled flatpak app's dataDir/flags
      flatpakActivationScripts =
        hmLib:
        lib.listToAttrs (
          lib.flatten (
            lib.mapAttrsToList (
              appId: appVal:
              let
                flatpakIdSafe = lib.replaceStrings [ "." ] [ "-" ] appId;
                flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);

                pruneCmds =
                  if flatpakSymlinks == [ ] then
                    ""
                  else
                    ''
                      # Clean up stale symlinks that are no longer defined in flatpakCfg
                      if [ -d "$HOME/.var/app/${appId}" ]; then
                        find "$HOME/.var/app/${appId}" -type l | while read -r symlink; do
                          # Only prune symlinks pointing to the host home directory to avoid breaking sandbox-internal symlinks
                          target=$(readlink "$symlink" || true)
                          if [[ "$target" == "$HOME/"* ]]; then
                            relpath="''${symlink#"$HOME/.var/app/${appId}/"}"
                            is_active=0
                            for active_guest in ${
                              lib.concatStringsSep " " (map (s: ''"${s.guest}"'') flatpakSymlinks)
                            }; do
                              if [ "$relpath" = "$active_guest" ]; then
                                is_active=1
                                break
                              fi
                            done
                            if [ "$is_active" -eq 0 ]; then
                              echo "Pruning stale Flatpak symlink: $relpath"
                              rm -f "$symlink"
                            fi
                          fi
                        done
                      fi
                    '';

                symlinkCmds = lib.concatMapStringsSep "\n" (
                  s:
                  if s.guest == ".zen" || s.guest == ".mozilla" then
                    builtins.abort "Sandbox escape: guest path cannot be ${s.guest}"
                  else
                    ''
                      # Ensure target directories exist on host
                      mkdir -p "$(dirname "$HOME/${s.host}")"
                      if [ ! -e "$HOME/${s.host}" ]; then
                        mkdir -p "$HOME/${s.host}"
                      fi

                      # If guest target exists (file or directory) and is not a symlink, backup it to prevent nesting/conflicts
                      if [ -e "$HOME/.var/app/${appId}/${s.guest}" ] && [ ! -L "$HOME/.var/app/${appId}/${s.guest}" ]; then
                        mv "$HOME/.var/app/${appId}/${s.guest}" "$HOME/.var/app/${appId}/${s.guest}.bak"
                      fi

                      mkdir -p "$(dirname "$HOME/.var/app/${appId}/${s.guest}")"
                      # Create direct out-of-store symlink
                      ln -sfn "$HOME/${s.host}" "$HOME/.var/app/${appId}/${s.guest}"
                    ''
                ) flatpakSymlinks;

                flatpakFlags = appVal.flags or { };
                flagsCmds =
                  if
                    flatpakFlags ? file && flatpakFlags.file != null && flatpakFlags ? text && flatpakFlags.text != ""
                  then
                    ''
                      mkdir -p "$(dirname "$HOME/.var/app/${appId}/${flatpakFlags.file}")"
                      cat << 'EOF' > "$HOME/.var/app/${appId}/${flatpakFlags.file}"
                      ${flatpakFlags.text}
                      EOF
                    ''
                  else
                    "";
              in
              lib.optionals (useFlatpak appId && (flatpakSymlinks != [ ] || flagsCmds != "")) [
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

      # Collect native packages for disabled flatpaks, and wrappers for enabled ones
      nativePackagesList = lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          let
            appEnabled = isAppEnabled appId;
            useFlatpakApp = useFlatpak appId;
            hmProgram = appVal.hmProgram or null;
            nativeInfo = getNativePkg appVal;
            nativePackages = nativeInfo.nativePackages;
            realNativePkg = nativeInfo.realNativePkg;
            binName =
              appVal.binName
                or (if realNativePkg != null && realNativePkg ? pname then realNativePkg.pname else null);
          in
          lib.optionals (appEnabled && (hmProgram == null || hmProgram.name == null)) (
            if useFlatpakApp then
              (lib.optionals (binName != null) [
                (pkgs.writeShellScriptBin binName ''
                  exec flatpak run ${appId} "$@"
                '')
              ])
            else
              nativePackages
          )
        ) flatpakCfg
      );

      # Home Manager programs integration
      hmProgramsConfig =
        hmPkgs:
        lib.listToAttrs (
          lib.flatten (
            lib.mapAttrsToList (
              appId: appVal:
              let
                appEnabled = isAppEnabled appId;
                useFlatpakApp = useFlatpak appId;
                hmProgram = appVal.hmProgram or null;
                nativeInfo = getNativePkg appVal;
                realNativePkg = nativeInfo.realNativePkg;
              in
              lib.optionals (appEnabled && hmProgram != null && hmProgram ? name && hmProgram.name != null) [
                (lib.nameValuePair hmProgram.name (
                  lib.recursiveUpdate {
                    enable = true;
                    ${hmProgram.packagePath or "package"} =
                      if useFlatpakApp then
                        lib.makeOverridable (
                          args:
                          hmPkgs.writeShellScriptBin (hmProgram.binName or hmProgram.name) ''
                            exec flatpak run ${appId} "$@"
                          ''
                        ) { }
                      else
                        realNativePkg;
                  } (hmProgram.extraConfig or { })
                ))
              ]
            ) flatpakCfg
          )
        );
    in
    {
      inherit
        flatpakPackages
        flatpakOverrides
        flatpakActivationScripts
        nativePackagesList
        hmProgramsConfig
        ;
    };
}
