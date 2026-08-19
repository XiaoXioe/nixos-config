{ lib }:

let
  # Resolve native package from submodule-typed cVal.
  # Priority: nativePkgs > native.package > package > null
  getNativePkg =
    cVal:
    let
      nativePkg =
        if cVal.nativePkgs != null then
          cVal.nativePkgs
        else if cVal.native != { } && cVal.native ? package then
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
    in
    {
      inherit nativePackages realNativePkg;
    };

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

      # Verify container existence; if not yet assembled, attempt on-demand initialization
      if ! ${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | grep -q "[|] ${containerName} [|]"; then
        echo "==> [distrobox-wrapper] Container '${containerName}' is not yet initialized." >&2
        if [ -f "$HOME/.config/distrobox/distrobox.ini" ]; then
          echo "==> [distrobox-wrapper] Initializing '${containerName}' from declarative configuration..." >&2
          ${pkgs.distrobox}/bin/distrobox assemble create --file "$HOME/.config/distrobox/distrobox.ini" --name "${containerName}" || true
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
    let
      inherit (ctx) pkgs distroboxCfg;
    in
    if distroboxCfg == { } then
      [ ]
    else
      lib.flatten (
        lib.mapAttrsToList (
          cId: cVal:
          let
            containerEnabled = isContainerEnabled ctx cId;
            useDistroboxContainer = useDistrobox ctx cId;
            nativeInfo = getNativePkg cVal;
            inherit (nativeInfo) nativePackages realNativePkg;
            fallbackBinName =
              if cVal.binName != null then
                cVal.binName
              else if realNativePkg != null then
                (realNativePkg.meta.mainProgram or (realNativePkg.pname or (lib.getName realNativePkg)))
              else
                null;

            # Collect all binary names to wrap: explicit binName + exportedBins + exported_bins
            allBinNames = lib.unique (
              (lib.optional (fallbackBinName != null) fallbackBinName) ++ cVal.exportedBins ++ cVal.exported_bins
            );
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
                ) allBinNames
              )
            else
              nativePackages
          )
        ) distroboxCfg
      );
}
