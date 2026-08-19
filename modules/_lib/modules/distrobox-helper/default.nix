{ lib, ... }:

let
  splitName = name: lib.splitString "." name;

  typesModule = import ./types.nix { inherit lib; };
  inherit (typesModule) containerSubmoduleType;

  isContainerEnabled =
    {
      name,
      distroboxCfg,
      config,
      singleContainerInfo,
      enableState,
      ...
    }:
    cId:
    let
      optionPath = splitName name;
      inherit (singleContainerInfo) isSingleContainer singleContainerId;
      cVal = distroboxCfg.${cId};
    in
    if !cVal.enable then
      false
    else if isSingleContainer && cId == singleContainerId then
      enableState
    else
      let
        optPath = optionPath ++ [
          "distroboxes"
          cId
          "enable"
        ];
      in
      if lib.hasAttrByPath optPath config.my then lib.getAttrFromPath optPath config.my else true;

  useDistrobox =
    ctx@{
      name,
      distroboxCfg,
      config,
      singleContainerInfo,
      ...
    }:
    cId:
    let
      optionPath = splitName name;
      inherit (singleContainerInfo) isSingleContainer singleContainerId;
      cVal = distroboxCfg.${cId};
      optPath =
        if isSingleContainer && cId == singleContainerId then
          optionPath
          ++ [
            "distrobox"
            "enable"
          ]
        else
          optionPath
          ++ [
            "distroboxes"
            cId
            "distrobox"
            "enable"
          ];
    in
    isContainerEnabled ctx cId
    && (
      if lib.hasAttrByPath optPath config.my then
        lib.getAttrFromPath optPath config.my
      else
        cVal.distrobox
    );

  optionsModule = import ./options.nix { inherit lib; };
  containersModule = import ./containers.nix { inherit lib; };
  packagesModule = import ./packages.nix { inherit lib; };

  inherit (optionsModule) mkDistroboxOptions;
  inherit (containersModule) mkDistroboxContainers;
  inherit (packagesModule) mkDistroboxPackagesList;
in
{
  inherit mkDistroboxOptions containerSubmoduleType;

  mkDistroboxConfigs =
    {
      name,
      distroboxCfg,
      options,
      config,
      pkgs,
      enableState,
      singleContainerInfo,
    }:
    let
      ctx = {
        inherit
          name
          distroboxCfg
          options
          config
          pkgs
          enableState
          singleContainerInfo
          ;
      };

      distroboxContainers = mkDistroboxContainers {
        inherit ctx useDistrobox;
      };

      distroboxPackagesList = mkDistroboxPackagesList {
        inherit ctx isContainerEnabled useDistrobox;
      };

      hasActiveContainers =
        distroboxCfg != { } && lib.any (cId: useDistrobox ctx cId) (builtins.attrNames distroboxCfg);
    in
    {
      inherit
        distroboxContainers
        distroboxPackagesList
        hasActiveContainers
        ;
    };
}
