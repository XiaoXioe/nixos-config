{ lib, ... }:

let
  flatpakHelper = import ../flatpak-helper { inherit lib; };
  distroboxHelper = import ../distrobox-helper { inherit lib; };
  inherit (distroboxHelper) containerSubmoduleType;
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
  distroboxCfg ? { },
  preservation ? { },
}:
let
  # Evaluate each distroboxCfg entry through the typed submodule so that:
  # 1. Unknown keys cause an evaluation error (type safety).
  # 2. All option defaults are applied (no more `or` fallbacks in sub-modules).
  typedDistroboxCfg = lib.mapAttrs (
    _cId: cVal:
    containerSubmoduleType.merge
      [ ]
      [
        {
          file = "<distroboxCfg>";
          value = cVal;
        }
      ]
  ) distroboxCfg;
in
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

        # Distrobox configuration processing — use typedDistroboxCfg (validated + defaults applied)
        hasDistroboxes = typedDistroboxCfg != { };
        isSingleContainer = hasDistroboxes && (lib.length (builtins.attrNames typedDistroboxCfg) == 1);
        singleContainerId =
          if isSingleContainer then builtins.elemAt (builtins.attrNames typedDistroboxCfg) 0 else null;
        singleContainerInfo = { inherit isSingleContainer singleContainerId; };

        distroboxConfigs = distroboxHelper.mkDistroboxConfigs {
          inherit
            name
            options
            config
            pkgs
            singleContainerInfo
            ;
          distroboxCfg = typedDistroboxCfg;
          enableState = cfg;
        };

        distroboxOptions = distroboxHelper.mkDistroboxOptions {
          inherit
            name
            options
            config
            singleContainerInfo
            ;
          distroboxCfg = typedDistroboxCfg;
        };

        resolvedDistroboxCfg = lib.mapAttrs (
          cId: cVal:
          let
            containerEnabled = distroboxHelper.isContainerEnabled {
              inherit name config singleContainerInfo;
              distroboxCfg = typedDistroboxCfg;
              enableState = cfg;
            } cId;
            useDB = distroboxHelper.useDistrobox {
              inherit name config singleContainerInfo;
              distroboxCfg = typedDistroboxCfg;
              enableState = cfg;
            } cId;
          in
          cVal
          // {
            enable = containerEnabled;
            distrobox = useDB;
          }
        ) typedDistroboxCfg;

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
              lib.recursiveUpdate
                (lib.optionalAttrs (name == "virtualisation.podman") {
                  _distroboxRegistry = lib.mkOption {
                    type = lib.types.attrsOf (lib.types.attrsOf distroboxHelper.containerSubmoduleType);
                    default = { };
                    internal = true;
                    description = "Internal registry of active Distrobox container configurations from modules.";
                  };
                })
                (
                  lib.setAttrByPath optionPath (
                    let
                      baseOptions = {
                        enable = lib.mkEnableOption (if description != "" then description else name);
                      };
                    in
                    baseOptions // flatpakOptions // distroboxOptions // options
                  )
                )
            );

        config = lib.mkMerge [
          (lib.mkIf (preservation != { }) {
            my.preservation.aspects."${name}" = {
              enable = cfg;
              rule = preservation;
            };
          })
          (lib.mkIf (cfg && hasDistroboxes) {
            my._distroboxRegistry."${name}" = resolvedDistroboxCfg;
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
              # Distrobox Home Manager configuration (wrappers & programs)
              (lib.mkIf (hasDistroboxes && userName != null) {
                home-manager.users.${userName} =
                  let
                    programsConfig = distroboxConfigs.hmProgramsConfig pkgs;
                  in
                  {
                    home.packages = distroboxConfigs.distroboxPackagesList;
                  }
                  // (lib.optionalAttrs (programsConfig != { }) {
                    programs = programsConfig;
                  });
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
