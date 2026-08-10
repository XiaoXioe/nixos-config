{ lib }:

let
  getNativePkg =
    appVal:
    let
      nativePkg = appVal.nativePkgs or (appVal.native.package or (appVal.package or null));
      nativePackages =
        if nativePkg == null then [ ] else (if builtins.isList nativePkg then nativePkg else [ nativePkg ]);
      realNativePkg = if nativePackages != [ ] then builtins.elemAt nativePackages 0 else null;
    in
    {
      inherit nativePackages realNativePkg;
    };

  mkFlatpakRunScript =
    pkgs: binName: appId:
    pkgs.writeShellScriptBin binName ''
      if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ "$DBUS_SESSION_BUS_ADDRESS" = "unix:path=/dev/null" ]; then
        if [ -S "/run/user/$(id -u)/bus" ]; then
          export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
        fi
      fi
      exec flatpak run ${appId} "$@"
    '';
in
{
  mkFlatpakPackages =
    { ctx, useFlatpak }:
    let
      inherit (ctx) flatpakCfg;
    in
    lib.flatten (
      lib.mapAttrsToList (
        appId: appVal:
        lib.optionals (useFlatpak ctx appId && !(appVal.skipInstall or false)) [
          (
            if appVal ? bundle then
              {
                inherit appId;
                inherit (appVal) bundle sha256;
              }
            else if appVal ? origin then
              {
                inherit appId;
                inherit (appVal) origin;
              }
            else
              appId
          )
        ]
      ) flatpakCfg
    );

  mkNativePackagesList =
    {
      ctx,
      isAppEnabled,
      useFlatpak,
    }:
    let
      inherit (ctx) pkgs;
      inherit (ctx) flatpakCfg;
    in
    lib.flatten (
      lib.mapAttrsToList (
        appId: appVal:
        let
          appEnabled = isAppEnabled ctx appId;
          useFlatpakApp = useFlatpak ctx appId;
          hmProgram = appVal.hmProgram or null;
          skipWrapper = appVal.skipNativeWrapper or false;
          nativeInfo = getNativePkg appVal;
          inherit (nativeInfo) nativePackages;
          inherit (nativeInfo) realNativePkg;
          binName =
            appVal.binName or (
              if realNativePkg != null then
                (realNativePkg.meta.mainProgram or (realNativePkg.pname or (lib.getName realNativePkg)))
              else
                null
            );
        in
        lib.optionals (appEnabled && !skipWrapper && (hmProgram == null || hmProgram.name == null)) (
          if useFlatpakApp then
            (
              if binName != null then
                [
                  (mkFlatpakRunScript pkgs binName appId)
                ]
              else
                lib.warn
                  "flatpak-helper: ${appId} has no binName or nativePkgs.pname — skipping CLI wrapper generation"
                  [ ]
            )
          else
            nativePackages
        )
      ) flatpakCfg
    );

  mkHmProgramsConfig =
    {
      ctx,
      isAppEnabled,
      useFlatpak,
    }:
    hmPkgs:
    let
      inherit (ctx) flatpakCfg;
    in
    lib.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          let
            appEnabled = isAppEnabled ctx appId;
            useFlatpakApp = useFlatpak ctx appId;
            hmProgram = appVal.hmProgram or null;
            nativeInfo = getNativePkg appVal;
            inherit (nativeInfo) realNativePkg;

            flatpakBin = mkFlatpakRunScript hmPkgs (hmProgram.binName or hmProgram.name) appId;
            flatpakPkg = (lib.makeOverridable (_: flatpakBin) { }) // {
              wrapper = _: flatpakBin;
            };
            defaultPkg = if useFlatpakApp then flatpakPkg else realNativePkg;
          in
          lib.optionals (appEnabled && hmProgram != null && hmProgram ? name && hmProgram.name != null) [
            (lib.nameValuePair hmProgram.name (
              {
                enable = true;
                ${hmProgram.packagePath or "package"} = defaultPkg;
              }
              // (hmProgram.extraConfig or { })
            ))
          ]
        ) flatpakCfg
      )
    );
}
