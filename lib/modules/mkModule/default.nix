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
        options.my = lib.setAttrByPath optionPath (
          let
            baseOptions = {
              enable = lib.mkEnableOption (if description != "" then description else name);
            };
          in
          baseOptions // flatpakOptions // options
        );

        config = lib.mkIf cfg (
          let
            hasUser = config.my ? user && config.my.user ? name;
            userName = if hasUser then config.my.user.name else null;
          in
          lib.mkMerge [
            resolvedNixosConfig
            (lib.mkIf (hmConfig != null && userName != null) {
              home-manager.users.${userName} = hmConfig;
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
                { lib, ... }:
                let
                  programsConfig = flatpakConfigs.hmProgramsConfig pkgs;
                in
                {
                  home.activation = flatpakConfigs.flatpakActivationScripts lib;
                  home.packages = flatpakConfigs.nativePackagesList;
                }
                // (lib.optionalAttrs (programsConfig != { }) {
                  programs = programsConfig;
                });
            })
          ]
        );
      }
    )
  ];
}
