{ lib, ... }:

let
  flatpakHelper = import ../flatpak-helper { inherit lib; };
in
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
  preservation ? { },
}:
# Validasi nama modul: harus dimulai huruf, hanya boleh alphanum/dots/dashes/underscores.
# Mencegah typo diam-diam (spasi, slash, karakter aneh) yang menghasilkan option path orphan.
assert
  builtins.match "[a-zA-Z][a-zA-Z0-9._-]*" name != null
  || builtins.throw "mkModule: invalid name '${name}'. Must match [a-zA-Z][a-zA-Z0-9._-]*.";
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
        cfg = lib.getAttrFromPath (optionPath ++ [ "enable" ]) config.my;

        # Flatpak configuration processing
        hasFlatpaks = flatpakCfg != { };
        isSingleApp = hasFlatpaks && (lib.length (builtins.attrNames flatpakCfg) == 1);
        singleAppId = if isSingleApp then builtins.elemAt (builtins.attrNames flatpakCfg) 0 else null;
        singleAppInfo = { inherit isSingleApp singleAppId; };

        flatpakConfigs = flatpakHelper.mkFlatpakConfigs {
          inherit
            name
            flatpakCfg
            options
            config
            pkgs
            singleAppInfo
            ;
          enableState = cfg;
        };

        flatpakOptions = flatpakHelper.mkFlatpakOptions {
          inherit
            name
            flatpakCfg
            options
            config
            singleAppInfo
            ;
        };

        resolvedNixosConfig =
          if builtins.isFunction nixosConfig then nixosConfig { inherit config lib pkgs; } else nixosConfig;
      in
      {
        options.my =
          lib.recursiveUpdate
            (lib.optionalAttrs (name == "hardware.preservation") {
              preservation.aspects = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options = {
                      enable = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Whether this preservation aspect is enabled.";
                      };
                      rule = lib.mkOption {
                        type = lib.types.submodule {
                          options = {
                            persist = lib.mkOption {
                              type = lib.types.bool;
                              default = false;
                              description = "Force preservation even if module is disabled.";
                            };
                            cleanupOnDisable = lib.mkOption {
                              type = lib.types.bool;
                              default = false;
                              description = "Clean up persisted directories when module is disabled.";
                            };
                            directories = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System directories to preserve (alias for systemDirectories).";
                            };
                            systemDirectories = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System directories to preserve.";
                            };
                            sysDirectories = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System directories to preserve (shorthand alias).";
                            };
                            userDirectories = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "User directories to preserve.";
                            };
                            files = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System files to preserve (alias for systemFiles).";
                            };
                            systemFiles = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System files to preserve.";
                            };
                            sysFiles = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "System files to preserve (shorthand alias).";
                            };
                            userFiles = lib.mkOption {
                              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                              default = [ ];
                              description = "User files to preserve.";
                            };
                          };
                        };
                        default = { };
                        description = "Preservation rule definition.";
                      };
                    };
                  }
                );
                default = { };
                description = "Co-located preservation rules registered by modules.";
              };
            })
            (
              lib.setAttrByPath optionPath (
                let
                  baseOptions = {
                    enable = lib.mkEnableOption (if description != "" then description else name);
                  };
                in
                baseOptions // flatpakOptions // options
              )
            );

        config = lib.mkMerge [
          (lib.mkIf (preservation != { }) {
            my.preservation.aspects."${name}" = {
              enable = cfg;
              rule = preservation;
            };
          })
          (lib.mkIf cfg (
            let
              hasUser = config.my ? user && config.my.user ? name;
              userName = if hasUser then config.my.user.name else null;
            in
            lib.mkMerge [
              resolvedNixosConfig
              (lib.mkIf (hmConfig != null && userName != null) {
                home-manager.users.${userName} = if builtins.isFunction hmConfig then hmConfig else (_: hmConfig);
              })
              # Flatpak-specific NixOS configuration
              (lib.mkIf (flatpakConfigs.flatpakPackages != [ ] || flatpakConfigs.flatpakOverrides != { }) {
                services.flatpak = {
                  packages = flatpakConfigs.flatpakPackages;
                  overrides = flatpakConfigs.flatpakOverrides;
                };
              })
              # Flatpak/Native Home Manager configuration
              (lib.mkIf ((hasFlatpaks || flatpakConfigs.nativePackagesList != [ ]) && userName != null) {
                home-manager.users.${userName} =
                  hmOpts@{ lib, ... }:
                  let
                    programsConfig = flatpakConfigs.hmProgramsConfig pkgs;
                  in
                  {
                    home.file = flatpakConfigs.hmFilesConfig hmOpts;
                    home.packages = flatpakConfigs.nativePackagesList;
                  }
                  // (lib.optionalAttrs (programsConfig != { }) {
                    programs = programsConfig;
                  });
              })
            ]
          ))
        ];
      }
    )
  ];
}
