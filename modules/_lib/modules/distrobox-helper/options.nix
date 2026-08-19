{ lib }:

{
  mkDistroboxOptions =
    {
      distroboxCfg,
      singleContainerInfo,
      ...
    }:
    let
      inherit (singleContainerInfo) isSingleContainer singleContainerId;
    in
    lib.optionalAttrs (distroboxCfg != { } && !isSingleContainer) {
      distroboxes = lib.mapAttrs (cId: cVal: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable Distrobox container '${cId}'.";
        };
        distrobox = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = cVal.distrobox;
            description = "Whether to use Distrobox for '${cId}' instead of the native package.";
          };
        };
      }) distroboxCfg;
    }
    // lib.optionalAttrs (distroboxCfg != { } && isSingleContainer) {
      distrobox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = distroboxCfg.${singleContainerId}.distrobox;
          description = "Whether to use Distrobox for '${singleContainerId}' instead of the native package.";
        };
      };
    };
}
