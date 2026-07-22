{ lib, ... }:

let
  utils = import ./utils.nix { inherit lib; };
  optionsHelper = import ./options.nix { inherit lib; };
  activationHelper = import ./activation.nix { inherit lib; };
  overridesHelper = import ./overrides.nix { inherit lib; };
  packagesHelper = import ./packages.nix { inherit lib; };
in
{
  inherit (optionsHelper) mkFlatpakOptions;

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

      isAppEnabled = utils.isAppEnabled;
      useFlatpak = utils.useFlatpak;

      flatpakPackages = packagesHelper.mkFlatpakPackages {
        inherit ctx useFlatpak;
      };

      flatpakOverrides = overridesHelper.mkFlatpakOverrides {
        inherit ctx useFlatpak;
      };

      flatpakActivationScripts = activationHelper.mkFlatpakActivationScripts {
        inherit ctx useFlatpak;
      };

      nativePackagesList = packagesHelper.mkNativePackagesList {
        inherit ctx isAppEnabled useFlatpak;
      };

      hmProgramsConfig = packagesHelper.mkHmProgramsConfig {
        inherit ctx isAppEnabled useFlatpak;
      };
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
