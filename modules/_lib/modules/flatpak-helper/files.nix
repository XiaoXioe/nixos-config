{ lib }:

let
  sanitizePath =
    p:
    if (builtins.match ".*\\.\\..*" p != null || lib.hasPrefix "/" p) then
      builtins.abort "Security Violation: Path traversal or absolute path detected in Flatpak guest configuration: ${p}"
    else
      p;
in
{
  mkHmFilesConfig =
    { ctx, useFlatpak }:
    hmOpts:
    lib.pipe ctx.flatpakCfg [
      (lib.filterAttrs (appId: _: useFlatpak ctx appId))
      (lib.mapAttrsToList (
        appId: appVal:
        let
          flatpakSymlinks = appVal.symlinks or (appVal.dataDir or [ ]);
          flatpakFlags = appVal.flags or { };
          flagsFile =
            if flatpakFlags ? file && flatpakFlags.file != null then sanitizePath flatpakFlags.file else null;

          symlinkAttrs = map (
            s:
            let
              guestPath = sanitizePath s.guest;
            in
            if guestPath == ".zen" || guestPath == ".mozilla" then
              builtins.abort "Sandbox escape: guest path cannot be ${s.guest}"
            else
              lib.nameValuePair ".var/app/${appId}/${guestPath}" {
                source = hmOpts.config.lib.file.mkOutOfStoreSymlink "${hmOpts.config.home.homeDirectory}/${s.host}";
                force = true;
              }
          ) flatpakSymlinks;

          flagsAttr = lib.optionals (flagsFile != null && flatpakFlags ? text && flatpakFlags.text != "") [
            (lib.nameValuePair ".var/app/${appId}/${flagsFile}" {
              text = flatpakFlags.text;
              force = true;
            })
          ];
        in
        symlinkAttrs ++ flagsAttr
      ))
      lib.flatten
      lib.listToAttrs
    ];
}
