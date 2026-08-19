{ lib }:

let
  distrosModule = import ./distros.nix { inherit lib; };
  inherit (distrosModule) detectDistro getDistroBasePackages getDistroPreInitHooks;

  joinSpace = list: lib.concatStringsSep " " list;
in
{
  mkDistroboxContainers =
    { ctx, useDistrobox }:
    let
      inherit (ctx) distroboxCfg;
    in
    if distroboxCfg == { } then
      { }
    else
      lib.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            cId: cVal:
            let
              enabled = useDistrobox ctx cId;
            in
            lib.optionals enabled [
              (
                let
                  targetDistro = if cVal.distro != "auto" then cVal.distro else detectDistro cVal.image;

                  basePackages = getDistroBasePackages {
                    distro = targetDistro;
                    inherit (cVal) deltaUpdates;
                  };

                  # Merge camelCase + snake_case aliases (both are guaranteed lists via submodule coercion)
                  userPackages = cVal.packages ++ cVal.additional_packages;
                  allPackages = basePackages ++ userPackages;

                  defaultPreInitHooks = getDistroPreInitHooks { distro = targetDistro; };
                  userPreInitHooks = cVal.preInitHooks ++ cVal.pre_init_hooks;
                  allPreInitHooks = defaultPreInitHooks ++ userPreInitHooks;

                  # Init hooks — no more redundant debdelta apt-get (already in additional_packages)
                  userInitHooks = cVal.initHooks ++ cVal.init_hooks;
                  allInitHooks = userInitHooks;

                  exportedApps = cVal.exportedApps ++ cVal.exported_apps;
                  exportedBins = cVal.exportedBins ++ cVal.exported_bins;

                  volumes = cVal.volumes ++ cVal.volume;
                  envFlags = lib.mapAttrsToList (
                    k: v: "--env ${k}=${lib.escapeShellArg (builtins.toString v)}"
                  ) cVal.env;
                  additionalFlags = envFlags ++ cVal.additionalFlags ++ cVal.additional_flags;

                  startNowValue = cVal.startNow || cVal.start_now;

                  resolvedHome =
                    if cVal.home != null then
                      cVal.home
                    else if cVal.isolatedHome then
                      "~/.local/share/distrobox-homes/${cId}"
                    else
                      null;

                  containerDef =
                    # Image is optional — when null, distrobox uses container_image_default from distrobox.conf
                    (lib.optionalAttrs (cVal.image != null) {
                      inherit (cVal) image;
                    })
                    // (lib.optionalAttrs (resolvedHome != null) {
                      home = resolvedHome;
                    })
                    // (lib.optionalAttrs (allPackages != [ ]) {
                      additional_packages = joinSpace (lib.unique allPackages);
                    })
                    // (lib.optionalAttrs (allInitHooks != [ ]) {
                      init_hooks = allInitHooks;
                    })
                    // (lib.optionalAttrs (allPreInitHooks != [ ]) {
                      pre_init_hooks = allPreInitHooks;
                    })
                    // (lib.optionalAttrs (exportedApps != [ ]) {
                      exported_apps = joinSpace exportedApps;
                    })
                    // (lib.optionalAttrs (exportedBins != [ ]) {
                      exported_bins = joinSpace exportedBins;
                    })
                    // (lib.optionalAttrs (cVal.exportedBinsPath != null) {
                      exported_bins_path = cVal.exportedBinsPath;
                    })
                    // (lib.optionalAttrs (volumes != [ ]) {
                      volume = volumes;
                    })
                    // (lib.optionalAttrs (additionalFlags != [ ]) {
                      additional_flags = additionalFlags;
                    })
                    // (lib.optionalAttrs cVal.init {
                      init = true;
                    })
                    // (lib.optionalAttrs cVal.pull {
                      pull = true;
                    })
                    // (lib.optionalAttrs cVal.nvidia {
                      nvidia = true;
                    })
                    // (lib.optionalAttrs cVal.root {
                      root = true;
                    })
                    // (lib.optionalAttrs cVal.replace {
                      replace = true;
                    })
                    // (lib.optionalAttrs startNowValue {
                      start_now = true;
                    })
                    // cVal.extraConfig;
                in
                lib.nameValuePair cId containerDef
              )
            ]
          ) distroboxCfg
        )
      );
}
