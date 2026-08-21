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
    if isSingleContainer && cId == singleContainerId then
      enableState && cVal.enable
    else
      let
        optPath = optionPath ++ [
          "distroboxes"
          cId
          "enable"
        ];
      in
      if lib.hasAttrByPath optPath config.my then lib.getAttrFromPath optPath config.my else cVal.enable;

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
  inherit (containersModule) mkDistroboxContainers mergeDistroboxContainers;
  inherit (packagesModule) mkDistroboxPackagesList mkDistroboxHmProgramsConfig;
in
{
  inherit
    mkDistroboxOptions
    containerSubmoduleType
    mkDistroboxContainers
    mergeDistroboxContainers
    isContainerEnabled
    useDistrobox
    ;

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

      # ── partial application — sub-modules only need cId ──────────
      # Bind ctx once here so that mkDistroboxContainers, mkDistroboxPackagesList,
      # and mkDistroboxHmProgramsConfig receive simple `cId -> bool` functions
      # instead of having to thread `ctx` through every call site.
      isEnabled = isContainerEnabled ctx;
      useDB = useDistrobox ctx;

      distroboxContainers = mkDistroboxContainers {
        inherit ctx;
        useDistrobox = useDB;
      };

      distroboxPackagesList = mkDistroboxPackagesList {
        inherit ctx;
        isContainerEnabled = isEnabled;
        useDistrobox = useDB;
      };

      hmProgramsConfig = mkDistroboxHmProgramsConfig {
        inherit ctx;
        isContainerEnabled = isEnabled;
        useDistrobox = useDB;
      };

      hasActiveContainers = distroboxCfg != { } && lib.any useDB (builtins.attrNames distroboxCfg);
    in
    {
      inherit
        distroboxContainers
        distroboxPackagesList
        hmProgramsConfig
        hasActiveContainers
        ;
    };
}
