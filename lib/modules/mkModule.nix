{ lib, ... }:

# Unified module builder for NixOS and Home Manager.
# Automatically creates 'options.my.${name}.enable' for global NixOS state.
{
  name,
  description ? "",
  options ? { },
  imports ? [ ],
  nixosConfig ? { },
  hmConfig ? null,
  flatpakCfg ? { },
}:
{
  imports = imports ++ [
    (
      { config, lib, pkgs, ... }:
      let
        optionPath = lib.splitString "." name;
        cfg = lib.getAttrFromPath (optionPath ++ [ "enable" ]) config.my;

        # Flatpak configuration processing
        hasFlatpaks = flatpakCfg != { };

        # Helper to check if a specific app is enabled
        isAppEnabled = appId:
          let
            appOptPath = optionPath ++ [ "flatpaks" appId "enable" ];
          in
          if lib.hasAttrByPath appOptPath config.my then
            lib.getAttrFromPath appOptPath config.my
          else
            true;

        # Helper to check if a specific flatpak app is using Flatpak
        useFlatpak = appId:
          let
            appOptPath = optionPath ++ [ "flatpaks" appId "flatpak" "enable" ];
            appVal = flatpakCfg.${appId};
          in
          isAppEnabled appId && (
            if lib.hasAttrByPath appOptPath config.my then
              lib.getAttrFromPath appOptPath config.my
            else
              appVal.enable or true
          );

        # Collect all flatpaks to install
        flatpakPackages = lib.flatten (
          lib.mapAttrsToList (appId: appVal:
            lib.optionals (useFlatpak appId) [
              (if appVal ? bundle then {
                inherit appId;
                inherit (appVal) bundle sha256;
              } else appId)
            ]
          ) flatpakCfg
        );

        # Collect overrides for enabled flatpaks
        flatpakOverrides = lib.listToAttrs (
          lib.flatten (
            lib.mapAttrsToList (appId: appVal:
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
        flatpakActivationScripts = hmLib: lib.listToAttrs (
          lib.flatten (
            lib.mapAttrsToList (appId: appVal:
              let
                flatpakIdSafe = lib.replaceStrings [ "." ] [ "-" ] appId;
                flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);
                symlinkCmds = lib.concatMapStringsSep "\n" (s: ''
                  # Ensure target directories exist on host
                  mkdir -p "$(dirname "$HOME/${s.host}")"
                  mkdir -p "$HOME/${s.host}"

                  # If guest target exists and is a directory (not a symlink), remove it to prevent nested symlinks
                  if [ -d "$HOME/.var/app/${appId}/${s.guest}" ] && [ ! -L "$HOME/.var/app/${appId}/${s.guest}" ]; then
                    rm -rf "$HOME/.var/app/${appId}/${s.guest}"
                  fi

                  mkdir -p "$(dirname "$HOME/.var/app/${appId}/${s.guest}")"
                  # Create direct out-of-store symlink
                  ln -sfn "$HOME/${s.host}" "$HOME/.var/app/${appId}/${s.guest}"
                '') flatpakSymlinks;

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
                    ${symlinkCmds}
                    ${flagsCmds}
                  ''
                ))
              ]
            ) flatpakCfg
          )
        );

        # Collect native packages for disabled flatpaks (only if no hmProgram is defined)
        nativePackagesList = lib.flatten (
          lib.mapAttrsToList (appId: appVal:
            let
              appEnabled = isAppEnabled appId;
              useFlatpakApp = useFlatpak appId;
              hmProgram = appVal.hmProgram or null;
              nativePkg = appVal.nativePkgs or (appVal.native.package or (appVal.package or null));
              nativePackages = if nativePkg == null then [ ] else (if builtins.isList nativePkg then nativePkg else [ nativePkg ]);
            in
            lib.optionals (appEnabled && !useFlatpakApp && (hmProgram == null || hmProgram.name == null)) nativePackages
          ) flatpakCfg
        );

        # Home Manager programs integration
        hmProgramsConfig = hmPkgs: lib.listToAttrs (
          lib.flatten (
            lib.mapAttrsToList (appId: appVal:
              let
                appEnabled = isAppEnabled appId;
                useFlatpakApp = useFlatpak appId;
                hmProgram = appVal.hmProgram or null;
                nativePkg = appVal.nativePkgs or (appVal.native.package or (appVal.package or null));
                nativePackages = if nativePkg == null then [ ] else (if builtins.isList nativePkg then nativePkg else [ nativePkg ]);
                realNativePkg = if nativePackages != [ ] then builtins.elemAt nativePackages 0 else null;
              in
              lib.optionals (appEnabled && hmProgram != null && hmProgram ? name && hmProgram.name != null) [
                (lib.nameValuePair hmProgram.name (
                  lib.recursiveUpdate {
                    enable = true;
                    ${hmProgram.packagePath or "package"} =
                      if useFlatpakApp then
                        lib.makeOverridable (args: hmPkgs.runCommand "empty-${hmProgram.name}" { } "mkdir -p $out") { }
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
        options.my = lib.setAttrByPath optionPath (
          {
            enable = lib.mkEnableOption (if description != "" then description else name);
          }
          // (lib.optionalAttrs hasFlatpaks {
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
                      lib.getAttrFromPath (optionPath ++ [ "flatpak" "enable" ]) config.my
                    else
                      appVal.enable or true;
                  description = "Whether to use Flatpak for ${appId} instead of the native package.";
                };
              };
            }) flatpakCfg;
          })
          // options
        );

        config = lib.mkIf cfg (
          lib.mkMerge [
            nixosConfig
            (lib.mkIf (hmConfig != null && hmConfig != { }) {
              home-manager.users.${config.my.user.name} = hmConfig;
            })
            # Flatpak-specific NixOS configuration
            (lib.mkIf (flatpakPackages != [ ] || flatpakOverrides != { }) {
              services.flatpak = {
                packages = flatpakPackages;
                overrides = flatpakOverrides;
              };
            })
            # Flatpak/Native Home Manager configuration
            (lib.mkIf (hasFlatpaks || nativePackagesList != [ ]) {
              home-manager.users.${config.my.user.name} = hmArgs@{ lib, ... }:
                let
                  programsConfig = hmProgramsConfig hmArgs.pkgs;
                in
                {
                  home.activation = flatpakActivationScripts lib;
                  home.packages = nativePackagesList;
                } // (lib.optionalAttrs (programsConfig != { }) {
                  programs = programsConfig;
                });
            })
          ]
        );
      }
    )
  ];
}
