{ lib, ... }:

let
  utils = import ./utils.nix { inherit lib; };
in
{
  # Collect all flatpaks to install
  mkFlatpakPackages =
    { ctx, useFlatpak }:
    let
      flatpakCfg = ctx.flatpakCfg;
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

  # Collect native packages for disabled flatpaks, and wrappers for enabled ones
  # Apps with skipNativeWrapper = true are skipped (they handle their own package override in hmConfig)
  mkNativePackagesList =
    {
      ctx,
      isAppEnabled,
      useFlatpak,
    }:
    let
      pkgs = ctx.pkgs;
      flatpakCfg = ctx.flatpakCfg;
    in
    lib.flatten (
      lib.mapAttrsToList (
        appId: appVal:
        let
          appEnabled = isAppEnabled ctx appId;
          useFlatpakApp = useFlatpak ctx appId;
          hmProgram = appVal.hmProgram or null;
          skipWrapper = appVal.skipNativeWrapper or false;
          nativeInfo = utils.getNativePkg appVal;
          nativePackages = nativeInfo.nativePackages;
          realNativePkg = nativeInfo.realNativePkg;
          binName =
            appVal.binName
              or (if realNativePkg != null && realNativePkg ? pname then realNativePkg.pname else null);
        in
        lib.optionals (appEnabled && !skipWrapper && (hmProgram == null || hmProgram.name == null)) (
          if useFlatpakApp then
            (
              if binName != null then
                [
                  (pkgs.writeShellScriptBin binName ''
                    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ "$DBUS_SESSION_BUS_ADDRESS" = "unix:path=/dev/null" ]; then
                      if [ -S "/run/user/$(id -u)/bus" ]; then
                        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
                      fi
                    fi
                    exec flatpak run ${appId} "$@"
                  '')
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

  # Home Manager programs integration
  mkHmProgramsConfig =
    {
      ctx,
      isAppEnabled,
      useFlatpak,
    }:
    hmPkgs:
    let
      flatpakCfg = ctx.flatpakCfg;
    in
    lib.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          let
            appEnabled = isAppEnabled ctx appId;
            useFlatpakApp = useFlatpak ctx appId;
            hmProgram = appVal.hmProgram or null;
            nativeInfo = utils.getNativePkg appVal;
            realNativePkg = nativeInfo.realNativePkg;
          in
          let
            flatpakBin = hmPkgs.writeShellScriptBin (hmProgram.binName or hmProgram.name) ''
              if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ "$DBUS_SESSION_BUS_ADDRESS" = "unix:path=/dev/null" ]; then
                if [ -S "/run/user/$(id -u)/bus" ]; then
                  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
                fi
              fi
              exec flatpak run ${appId} "$@"
            '';
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
