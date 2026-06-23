{ lib, ... }:

# Helper for applications that can be configured either as Flatpak or Native (Nixpkgs).
# Automatically manages packages, overrides, symlinks, and flags.
{
  name,
  description ? "",
  options ? { },
  imports ? [ ],
  flatpak ? null,
  native ? null,
  hmProgram ? null,
  nixosConfig ? { },
  hmConfig ? null,
}:
{
  imports = imports ++ [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        optionPath = lib.splitString "." name;
        cfg = lib.getAttrFromPath optionPath config.my;

        hasFlatpak = flatpak != null;
        enabled = lib.getAttrFromPath (optionPath ++ [ "enable" ]) config.my;

        useFlatpak =
          hasFlatpak
          && (
            if
              lib.hasAttrByPath (
                optionPath
                ++ [
                  "flatpak"
                  "enable"
                ]
              ) config.my
            then
              lib.getAttrFromPath (
                optionPath
                ++ [
                  "flatpak"
                  "enable"
                ]
              ) config.my
            else
              true
          );

        flatpakId = if hasFlatpak then flatpak.appId else null;
        flatpakIdSafe = if flatpakId != null then flatpakId else "dummy";
        flatpakSymlinks = if hasFlatpak then (flatpak.symlinks or [ ]) else [ ];
        flatpakFlags = if hasFlatpak then (flatpak.flags or { }) else { };

        # Home Manager activation script to securely create host/guest directories and create symlinks.
        # Avoids Nix Store path propagation which causes bubblewrap sandbox creation to crash.
        flatpakActivationScript =
          let
            symlinkCmds = lib.concatMapStringsSep "\n" (s: ''
              # Ensure target directories exist on host
              mkdir -p "$(dirname "$HOME/${s.host}")"
              mkdir -p "$HOME/${s.host}"

              # If guest target exists and is a directory (not a symlink), remove it to prevent nested symlinks
              if [ -d "$HOME/.var/app/${flatpakIdSafe}/${s.guest}" ] && [ ! -L "$HOME/.var/app/${flatpakIdSafe}/${s.guest}" ]; then
                rm -rf "$HOME/.var/app/${flatpakIdSafe}/${s.guest}"
              fi

              mkdir -p "$(dirname "$HOME/.var/app/${flatpakIdSafe}/${s.guest}")"
              # Create direct out-of-store symlink
              ln -sfn "$HOME/${s.host}" "$HOME/.var/app/${flatpakIdSafe}/${s.guest}"
            '') flatpakSymlinks;

            flagsCmds =
              if
                flatpakFlags ? file && flatpakFlags.file != null && flatpakFlags ? text && flatpakFlags.text != ""
              then
                ''
                  mkdir -p "$(dirname "$HOME/.var/app/${flatpakIdSafe}/${flatpakFlags.file}")"
                  cat << 'EOF' > "$HOME/.var/app/${flatpakIdSafe}/${flatpakFlags.file}"
                  ${flatpakFlags.text}
                  EOF
                ''
              else
                "";
          in
          lib.optionalString (useFlatpak && (flatpakSymlinks != [ ] || flagsCmds != "")) ''
            ${symlinkCmds}
            ${flagsCmds}
          '';

        # Automate flatpak filesystem overrides dynamically for symlinks
        flatpakOverrides =
          let
            symlinkFilesystems = map (s: "/home/${config.my.user.name}/${s.host}") flatpakSymlinks;
            baseFilesystems = [ "/nix/store:ro" ] ++ symlinkFilesystems;
            configuredFilesystems = if hasFlatpak then (flatpak.overrides.Context.filesystems or [ ]) else [ ];
            finalFilesystems = lib.unique (baseFilesystems ++ configuredFilesystems);
          in
          lib.recursiveUpdate (if hasFlatpak then (flatpak.overrides or { }) else { }) {
            Context.filesystems = finalFilesystems;
          };
      in
      {
        options.my = lib.setAttrByPath optionPath (
          {
            enable = lib.mkEnableOption (if description != "" then description else name);
          }
          // (lib.optionalAttrs hasFlatpak {
            flatpak = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether to use Flatpak for ${name} instead of the native package.";
              };
            };
          })
          // options
        );

        config = lib.mkIf enabled (
          lib.mkMerge [
            # NixOS level configuration
            {
              # Register flatpak application if requested
              services.flatpak = lib.mkIf useFlatpak {
                packages = [
                  (if flatpak ? bundle then {
                    appId = flatpak.appId;
                    bundle = flatpak.bundle;
                    sha256 = flatpak.sha256;
                  } else flatpakId)
                ];
                overrides."${flatpakId}" = flatpakOverrides;
              };

              # Install native package globally if flatpak is disabled and not using Home Manager programs
              environment.systemPackages =
                lib.mkIf
                  (
                    !useFlatpak
                    && native != null
                    && native ? package
                    && native.package != null
                    && (hmProgram == null || hmProgram.name == null)
                  )
                  [
                    native.package
                  ];
            }

            # User-supplied raw NixOS configuration
            nixosConfig

            # Home Manager level configuration
            (lib.mkIf (hasFlatpak || hmConfig != null || hmProgram != null) {
              home-manager.users.${config.my.user.name} =
                hmArgs@{ lib, pkgs, ... }:
                let
                  hmCfg =
                    if builtins.isFunction hmConfig then
                      hmConfig hmArgs
                    else
                      (if hmConfig != null then hmConfig else { });

                  # Setup Home Manager program integration if requested
                  hmProgramCfg =
                    if hmProgram != null && hmProgram ? name && hmProgram.name != null then
                      {
                        programs.${hmProgram.name} = {
                          enable = true;
                          # Use a dummy package override for Flatpak to allow configurations/extensions without native binary download,
                          # or use the real native package otherwise.
                          ${hmProgram.packagePath or "package"} =
                            if useFlatpak then
                              lib.makeOverridable (args: pkgs.runCommand "empty-${hmProgram.name}" { } "mkdir -p $out") { }
                            else
                              (if native != null && native ? package && native.package != null then native.package else null);
                        }
                        // (hmProgram.extraConfig or { });
                      }
                    else
                      { };

                  # Install native package at Home Manager level if flatpak is disabled and not using Home Manager programs
                  nativePackagesCfg =
                    if
                      !useFlatpak
                      && native != null
                      && native ? package
                      && native.package != null
                      && (hmProgram == null || hmProgram.name == null)
                    then
                      {
                        home.packages = [ native.package ];
                      }
                    else
                      { };

                  # Register activation script for symlinks and flags
                  activationCfg = lib.optionalAttrs (useFlatpak && flatpakActivationScript != "") {
                    home.activation."setup-flatpak-${lib.replaceStrings [ "." ] [ "-" ] flatpakIdSafe}" =
                      lib.hm.dag.entryAfter [ "writeBoundary" ]
                        flatpakActivationScript;
                  };
                in
                lib.mkMerge [
                  hmProgramCfg
                  nativePackagesCfg
                  activationCfg
                  hmCfg
                ];
            })
          ]
        );
      }
    )
  ];
}
