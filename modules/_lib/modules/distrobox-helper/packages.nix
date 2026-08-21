{ lib }:

let
  utils = import ./utils.nix { inherit lib; };
  inherit (utils) normalizeCval;

  # Resolves which native Nix package to use when distrobox mode is disabled.
  # Priority: nativePkgs > native.package > package.
  # Emits lib.warn when more than one source is non-null to avoid silent surprises.
  getNativePkg =
    cVal:
    let
      hasNativePkgs = cVal.nativePkgs != null;
      hasNativeAttr = cVal.native != { } && cVal.native ? package;
      hasPackage = cVal.package != null;
      conflictCount = lib.count lib.id [
        hasNativePkgs
        hasNativeAttr
        hasPackage
      ];
      nativePkg =
        if hasNativePkgs then
          cVal.nativePkgs
        else if hasNativeAttr then
          cVal.native.package
        else
          cVal.package;
      nativePackages =
        if nativePkg == null then
          [ ]
        else if builtins.isList nativePkg then
          nativePkg
        else
          [ nativePkg ];
      realNativePkg = if nativePackages != [ ] then builtins.elemAt nativePackages 0 else null;
      result = { inherit nativePackages realNativePkg; };
    in
    if conflictCount > 1 then
      lib.warn "distrobox-helper: multiple native package sources set (nativePkgs / native.package / package). Using nativePkgs priority." result
    else
      result;

  # Generates a host-side Nix wrapper script that enters the container and runs
  # the given binary. Uses a direct 'distrobox enter -- true' probe to check
  # container existence — more robust than parsing `distrobox list` output which
  # can change format across distrobox versions.
  mkDistroboxRunScript =
    {
      pkgs,
      binName,
      containerName,
      env ? { },
      binArgs ? null,
    }:
    let
      envPairs = lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg (builtins.toString v)}") env;
      envPrefix = if envPairs != [ ] then "env " + (lib.concatStringsSep " " envPairs) + " " else "";
      extraArgs =
        if builtins.isString binArgs then
          " " + binArgs
        else if builtins.isAttrs binArgs && binArgs ? ${binName} then
          " " + binArgs.${binName}
        else
          "";
    in
    pkgs.writeShellScriptBin binName ''
      set -eo pipefail

      if ! ${pkgs.distrobox}/bin/distrobox enter "${containerName}" -- true 2>/dev/null; then
        echo "==> [distrobox-wrapper] Container '${containerName}' is not yet initialized." >&2
        if [ -f "$HOME/.config/distrobox/containers.ini" ]; then
          echo "==> [distrobox-wrapper] Initializing '${containerName}' from declarative configuration..." >&2
          ${pkgs.distrobox}/bin/distrobox assemble create --file "$HOME/.config/distrobox/containers.ini" --name "${containerName}" || true
        elif [ -f "$HOME/.config/distrobox/distrobox.ini" ]; then
          echo "==> [distrobox-wrapper] Initializing '${containerName}' from declarative configuration..." >&2
          ${pkgs.distrobox}/bin/distrobox assemble create --file "$HOME/.config/distrobox/distrobox.ini" --name "${containerName}" || true
        fi
        if command -v distrobox-sync >/dev/null 2>&1; then
          echo "==> [distrobox-wrapper] Synchronizing packages for '${containerName}'..." >&2
          distrobox-sync || true
        fi
      fi

      # Self-healing: if binary is missing in container, run distrobox-sync to install declared packages.
      if ! ${pkgs.distrobox}/bin/distrobox enter "${containerName}" -- sh -c "command -v ${binName} >/dev/null 2>&1"; then
        if command -v distrobox-sync >/dev/null 2>&1; then
          echo "==> [distrobox-wrapper] '${binName}' not found in '${containerName}', running distrobox-sync..." >&2
          distrobox-sync || true
        fi
      fi

      exec ${pkgs.distrobox}/bin/distrobox enter "${containerName}" -- ${envPrefix}${binName}${extraArgs} "$@"
    '';
in
{
  mkDistroboxPackagesList =
    {
      ctx,
      isContainerEnabled,
      useDistrobox,
    }:
    # isContainerEnabled and useDistrobox are partially-applied: cId -> bool
    let
      inherit (ctx) pkgs distroboxCfg;
    in
    if distroboxCfg == { } then
      [ ]
    else
      lib.flatten (
        lib.mapAttrsToList (
          cId: rawVal:
          let
            cVal = normalizeCval rawVal;
            containerEnabled = isContainerEnabled cId;
            useDistroboxContainer = useDistrobox cId;
            nativeInfo = getNativePkg cVal;
            inherit (nativeInfo) nativePackages realNativePkg;
            fallbackBinName =
              if cVal.binName != null then
                cVal.binName
              else if realNativePkg != null then
                (realNativePkg.meta.mainProgram or (realNativePkg.pname or (lib.getName realNativePkg)))
              else
                null;

            allBinNames = lib.unique (
              (lib.optional (fallbackBinName != null) fallbackBinName) ++ cVal.exportedBins
            );

            # If passWrapperAsPackage: skip the primary bin (injected via programs.<name>.package).
            wrappedBins =
              if cVal.hmProgram != null && cVal.hmProgram.passWrapperAsPackage then
                let
                  passedBin = if cVal.hmProgram.binName != null then cVal.hmProgram.binName else fallbackBinName;
                in
                lib.filter (b: b != passedBin) allBinNames
              else
                allBinNames;
          in
          lib.optionals containerEnabled (
            if useDistroboxContainer then
              lib.optionals cVal.generateHostWrapper (
                map (
                  bName:
                  mkDistroboxRunScript {
                    inherit pkgs;
                    binName = bName;
                    containerName = cId;
                    inherit (cVal) env binArgs;
                  }
                ) wrappedBins
              )
            else
              nativePackages
          )
        ) distroboxCfg
      );

  mkDistroboxHmProgramsConfig =
    {
      ctx,
      isContainerEnabled,
      useDistrobox,
    }:
    # isContainerEnabled and useDistrobox are partially-applied: cId -> bool
    hmPkgs:
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
              cVal = normalizeCval rawVal;
              containerEnabled = isContainerEnabled cId;
              useDistroboxContainer = useDistrobox cId;
              inherit (cVal) hmProgram;
              nativeInfo = getNativePkg cVal;
              inherit (nativeInfo) realNativePkg;

              fallbackBinName =
                if hmProgram != null && hmProgram.binName != null then
                  hmProgram.binName
                else if cVal.binName != null then
                  cVal.binName
                else if realNativePkg != null then
                  (realNativePkg.meta.mainProgram or (realNativePkg.pname or (lib.getName realNativePkg)))
                else
                  null;

              distroboxBin =
                if fallbackBinName != null then
                  mkDistroboxRunScript {
                    pkgs = hmPkgs;
                    binName = fallbackBinName;
                    containerName = cId;
                    inherit (cVal) env binArgs;
                  }
                else
                  null;

              containerPkg =
                if hmProgram != null && hmProgram.package != null then
                  hmProgram.package
                else if hmProgram != null && hmProgram.passWrapperAsPackage then
                  distroboxBin
                else
                  null;

              defaultPkg = if useDistroboxContainer then containerPkg else realNativePkg;
            in
            lib.optionals (containerEnabled && hmProgram != null && hmProgram ? name && hmProgram.name != null)
              [
                (lib.nameValuePair hmProgram.name (
                  {
                    enable = true;
                    ${hmProgram.packagePath} = defaultPkg;
                  }
                  // hmProgram.extraConfig
                ))
              ]
          ) distroboxCfg
        )
      );
}
