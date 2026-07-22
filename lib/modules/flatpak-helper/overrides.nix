{ lib, ... }:

{
  mkFlatpakOverrides =
    { ctx, useFlatpak }:
    let
      config = ctx.config;
      flatpakCfg = ctx.flatpakCfg;
    in
    lib.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          appId: appVal:
          lib.optionals (useFlatpak ctx appId) [
            (
              let
                hasSymlinks = (appVal.symlinks or (appVal.dataDir or [ ])) != [ ];
                hasFlags = appVal ? flags && (appVal.flags.text or "") != "";
                hasHmProgram = appVal ? hmProgram;

                needNixStore =
                  if appVal ? needNixStore then appVal.needNixStore else (hasSymlinks || hasFlags || hasHmProgram);

                nixStoreFilesystems = lib.optionals needNixStore [ "/nix/store:ro" ];
                flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);
                symlinkFilesystems = map (s: "/home/${config.my.user.name}/${s.host}") flatpakSymlinks;
                baseFilesystems = nixStoreFilesystems ++ symlinkFilesystems;
                configuredFilesystems = appVal.overrides.Context.filesystems or [ ];
                finalFilesystems = lib.unique (baseFilesystems ++ configuredFilesystems);
              in
              lib.nameValuePair appId (
                let
                  ovr = appVal.overrides or { };
                  ctx = ovr.Context or { };
                in
                ovr
                // {
                  Context = ctx // {
                    filesystems = finalFilesystems;
                  };
                }
              )
            )
          ]
        ) flatpakCfg
      )
    );
}
