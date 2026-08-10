{ lib, ... }:

let
  splitName = name: lib.splitString "." name;

  isAppEnabled =
    {
      name,
      flatpakCfg,
      config,
      singleAppInfo,
      enableState,
      ...
    }:
    appId:
    let
      optionPath = splitName name;
      inherit (singleAppInfo) isSingleApp;
      inherit (singleAppInfo) singleAppId;
      appVal = flatpakCfg.${appId};
    in
    if !(appVal.enable or true) then
      false
    else if isSingleApp && appId == singleAppId then
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

  useFlatpak =
    ctx@{
      name,
      flatpakCfg,
      config,
      singleAppInfo,
      enableState,
      ...
    }:
    appId:
    let
      optionPath = splitName name;
      inherit (singleAppInfo) isSingleApp;
      inherit (singleAppInfo) singleAppId;
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
    isAppEnabled ctx appId
    && (
      if lib.hasAttrByPath appOptPath config.my then
        lib.getAttrFromPath appOptPath config.my
      else
        appVal.flatpak or true
    );

  optionsModule = import ./options.nix { inherit lib; };
  packagesModule = import ./packages.nix { inherit lib; };
  overridesModule = import ./overrides.nix { inherit lib; };
  filesModule = import ./files.nix { inherit lib; };

  inherit (optionsModule) mkFlatpakOptions;
  inherit (packagesModule) mkFlatpakPackages mkNativePackagesList mkHmProgramsConfig;
  inherit (overridesModule) mkFlatpakOverrides;
  inherit (filesModule) mkHmFilesConfig;
in
{
  inherit mkFlatpakOptions;

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
      ctx = {
        inherit
          name
          flatpakCfg
          options
          config
          pkgs
          enableState
          singleAppInfo
          ;
      };

      flatpakPackages = mkFlatpakPackages {
        inherit ctx useFlatpak;
      };

      flatpakOverrides = mkFlatpakOverrides {
        inherit ctx useFlatpak;
      };

      hmFilesConfig = mkHmFilesConfig {
        inherit ctx useFlatpak;
      };

      nativePackagesList = mkNativePackagesList {
        inherit ctx isAppEnabled useFlatpak;
      };

      hmProgramsConfig = mkHmProgramsConfig {
        inherit ctx isAppEnabled useFlatpak;
      };
    in
    {
      inherit
        flatpakPackages
        flatpakOverrides
        hmFilesConfig
        nativePackagesList
        hmProgramsConfig
        ;
    };
}
