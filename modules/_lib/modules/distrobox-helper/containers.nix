{ lib }:

let
  distrosModule = import ./distros.nix { inherit lib; };
  inherit (distrosModule)
    detectDistro
    getDistroBasePackages
    getDistroPreInitHooks
    getDistroAurSupport
    ;

  features = import ./features { inherit lib; };
  inherit (features) getFeaturePreInitHooks getFeatureInitHooks;

  utils = import ./utils.nix { inherit lib; };
  inherit (utils) normalizeCval;

  joinSpace = list: lib.concatStringsSep " " list;

  # Collapses a multi-line shell snippet into a single-line entry suitable
  # for distrobox.ini — strips blank lines and comments, joins with ' && '.
  sanitizeHook =
    hook:
    let
      lines = lib.splitString "\n" hook;
      trimmed = map lib.trim lines;
      nonEmpty = lib.filter (l: l != "" && !(lib.hasPrefix "#" l)) trimmed;
    in
    lib.concatStringsSep " && " nonEmpty;
in
{
  mkDistroboxContainers =
    { ctx, useDistrobox }:
    # useDistrobox is the partially-applied form: cId -> bool
    let
      inherit (ctx) distroboxCfg;
    in
    if distroboxCfg == { } then
      { }
    else
      lib.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            cId: rawVal:
            let
              # Merge camelCase + snake_case aliases into canonical names once.
              cVal = normalizeCval rawVal;
              enabled = (cVal.enable or true) && (useDistrobox cId);
            in
            lib.optionals enabled [
              (
                let
                  targetDistro = if cVal.distro != "auto" then cVal.distro else detectDistro cVal.image;

                  basePackages = getDistroBasePackages {
                    distro = targetDistro;
                    inherit (cVal) deltaUpdates;
                  };

                  # AUR support is provided by the arch-linux distro module;
                  # null for all other distros.
                  aurSupport = getDistroAurSupport { distro = targetDistro; };

                  aurBuildPrereqs = lib.optionals (
                    aurSupport != null && cVal.aurPackages != [ ]
                  ) aurSupport.aurBuildPrereqs;

                  allPackages = basePackages ++ aurBuildPrereqs ++ cVal.packages;

                  defaultPreInitHooks = getDistroPreInitHooks { distro = targetDistro; };
                  featurePreInitHooks = getFeaturePreInitHooks cVal;
                  allPreInitHooks = map sanitizeHook (
                    lib.unique (defaultPreInitHooks ++ featurePreInitHooks ++ cVal.preInitHooks)
                  );

                  # AUR hooks are single-line strings (from arch-linux module) —
                  # no sanitizeHook needed. User initHooks may be multi-line.
                  aurInitHooks = lib.optionals (aurSupport != null && cVal.aurPackages != [ ]) (
                    map aurSupport.mkAurBuildHook (lib.unique cVal.aurPackages)
                  );
                  featureInitHooks = getFeatureInitHooks cVal;
                  allInitHooks = lib.unique (aurInitHooks ++ featureInitHooks ++ map sanitizeHook cVal.initHooks);

                  envFlags = lib.mapAttrsToList (
                    k: v: "--env ${k}=${lib.escapeShellArg (builtins.toString v)}"
                  ) cVal.env;
                  additionalFlags = envFlags ++ cVal.additionalFlags;

                  defaultVolumes = [ "/nix/store:/nix/store:ro" ];
                  volumes = lib.unique (defaultVolumes ++ cVal.volumes);

                  resolvedHome =
                    if cVal.home != null then
                      cVal.home
                    else if cVal.isolatedHome then
                      "~/.local/share/distrobox-homes/${cId}"
                    else
                      null;

                  containerDef =
                    (lib.optionalAttrs (cVal.image != null) { inherit (cVal) image; })
                    // (lib.optionalAttrs (cVal.clone != null) { inherit (cVal) clone; })
                    // (lib.optionalAttrs (resolvedHome != null) { home = resolvedHome; })
                    // (lib.optionalAttrs (allPackages != [ ]) {
                      additional_packages = joinSpace (lib.unique allPackages);
                    })
                    // (lib.optionalAttrs (allInitHooks != [ ]) { init_hooks = allInitHooks; })
                    // (lib.optionalAttrs (allPreInitHooks != [ ]) { pre_init_hooks = allPreInitHooks; })
                    // (lib.optionalAttrs (cVal.exportedApps != [ ]) {
                      exported_apps = joinSpace cVal.exportedApps;
                    })
                    // (lib.optionalAttrs (cVal.exportedBins != [ ]) {
                      exported_bins = joinSpace cVal.exportedBins;
                    })
                    // (lib.optionalAttrs (cVal.exportedBinsPath != null) {
                      exported_bins_path = cVal.exportedBinsPath;
                    })
                    // (lib.optionalAttrs (cVal.entry != null) { inherit (cVal) entry; })
                    // (lib.optionalAttrs (volumes != [ ]) { volume = volumes; })
                    // (lib.optionalAttrs (additionalFlags != [ ]) { additional_flags = additionalFlags; })
                    // (lib.optionalAttrs cVal.init { init = true; })
                    // (lib.optionalAttrs cVal.pull { pull = true; })
                    // (lib.optionalAttrs cVal.nvidia { nvidia = true; })
                    // (lib.optionalAttrs cVal.root { root = true; })
                    // (lib.optionalAttrs cVal.replace { replace = true; })
                    // (lib.optionalAttrs cVal.startNow { start_now = true; })
                    // cVal.extraConfig;
                in
                lib.nameValuePair cId containerDef
              )
            ]
          ) distroboxCfg
        )
      );

  mergeDistroboxContainers =
    allConfigs:
    if allConfigs == [ ] || allConfigs == { } then
      { }
    else
      let
        configList = if builtins.isList allConfigs then allConfigs else builtins.attrValues allConfigs;
        allCIds = lib.unique (lib.concatLists (map builtins.attrNames configList));
      in
      lib.listToAttrs (
        map (
          cId:
          let
            rawVals = lib.filter (v: v != null) (map (r: r.${cId} or null) configList);
            # Normalize aliases before merging so all fields are canonical.
            cVals = map normalizeCval rawVals;
            # Only active container configurations contribute packages, hooks, and dependencies.
            activeVals = lib.filter (c: (c.enable or true) && (c.distrobox or true)) cVals;
            effectiveVals = if activeVals != [ ] then activeVals else cVals;

            headVal = builtins.elemAt effectiveVals 0;
            nonNullImage = lib.findFirst (c: c.image != null) null effectiveVals;
            nonNullClone = lib.findFirst (c: c.clone != null) null effectiveVals;
            nonNullEntry = lib.findFirst (c: c.entry != null) null effectiveVals;
            nonAutoDistro = lib.findFirst (c: c.distro != "auto") null effectiveVals;
            nonNullHome = lib.findFirst (c: c.home != null) null effectiveVals;
            mergedVal = headVal // {
              enable = activeVals != [ ];
              image = if nonNullImage != null then nonNullImage.image else null;
              clone = if nonNullClone != null then nonNullClone.clone else null;
              entry = if nonNullEntry != null then nonNullEntry.entry else null;
              distro = if nonAutoDistro != null then nonAutoDistro.distro else "auto";
              home = if nonNullHome != null then nonNullHome.home else null;
              # Canonical merged fields (only from active container declarations).
              packages = lib.unique (lib.concatLists (map (c: c.packages) activeVals));
              aurPackages = lib.unique (lib.concatLists (map (c: c.aurPackages) activeVals));
              preInitHooks = lib.unique (lib.concatLists (map (c: c.preInitHooks) activeVals));
              initHooks = lib.unique (lib.concatLists (map (c: c.initHooks) activeVals));
              exportedApps = lib.unique (lib.concatLists (map (c: c.exportedApps) activeVals));
              exportedBins = lib.unique (lib.concatLists (map (c: c.exportedBins) activeVals));
              volumes = lib.unique (lib.concatLists (map (c: c.volumes) activeVals));
              additionalFlags = lib.unique (lib.concatLists (map (c: c.additionalFlags) activeVals));
              env = lib.foldl (acc: c: acc // c.env) { } activeVals;
              isolatedHome = lib.any (c: c.isolatedHome) activeVals;
              init = lib.any (c: c.init) activeVals;
              pull = lib.any (c: c.pull) activeVals;
              nvidia = lib.any (c: c.nvidia) activeVals;
              root = lib.any (c: c.root) activeVals;
              replace = lib.any (c: c.replace) activeVals;
              startNow = lib.any (c: c.startNow) activeVals;
              deltaUpdates = lib.all (c: c.deltaUpdates) activeVals;
              # Feature options merge
              extraTesting = lib.any (c: c.extraTesting or false) activeVals;
              chaoticAur = lib.any (c: c.chaoticAur or false) activeVals;
              copr = lib.unique (lib.concatLists (map (c: c.copr or [ ]) activeVals));
              rpmfusion = {
                free = lib.any (c: (c.rpmfusion or { }).free or false) activeVals;
                unfree = lib.any (c: (c.rpmfusion or { }).unfree or false) activeVals;
              };
              symlinks = lib.foldl (acc: c: acc // (c.symlinks or { })) { } activeVals;
              extraConfig = lib.foldl (acc: c: acc // c.extraConfig) { } activeVals;
              # Reset alias fields after merge — they have been folded into the
              # canonical names above and must not leak downstream.
              additional_packages = [ ];
              aur = [ ];
              pre_init_hooks = [ ];
              init_hooks = [ ];
              exported_apps = [ ];
              exported_bins = [ ];
              volume = [ ];
              additional_flags = [ ];
              start_now = false;
            };
          in
          lib.nameValuePair cId mergedVal
        ) allCIds
      );
}
