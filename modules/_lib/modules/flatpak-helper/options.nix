{ lib }:

let
  splitName = name: lib.splitString "." name;
in
{
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
      inherit (singleAppInfo) isSingleApp;
      inherit (singleAppInfo) singleAppId;
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
                appVal.flatpak or true;
            description = "Whether to use Flatpak for ${appId} instead of the native package.";
          };
        };
      }) flatpakCfg;
    }
    // lib.optionalAttrs (flatpakCfg != { } && isSingleApp) {
      flatpak = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = flatpakCfg.${singleAppId}.flatpak or true;
          description = "Whether to use Flatpak for ${singleAppId} instead of the native package.";
        };
      };
    };
}
