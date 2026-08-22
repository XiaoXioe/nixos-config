{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.materialgram;

  materialgramNative = (selfLib.mkNativeApp pkgs) {
    name = "materialgram";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "materialgram";
    execPath = "usr/bin/materialgram";
    binName = "materialgram";
  };
in
selfLib.mkModule {
  name = "apps.social.materialgram";
  description = "Materialgram Desktop Messaging application";

  hmConfig = {
    home.packages = [ materialgramNative ];
  };

  nixosConfig =
    { config, ... }:
    {
      my.services.storage.btrfs-nocow-migration.nocowDirectories = [
        ".local/share/materialgram/tdata"
      ];
      my.services.vmtouch.paths = [
        materialgramNative
        "/home/${config.my.user.name}/.local/share/materialgram"
      ];
    };
}
