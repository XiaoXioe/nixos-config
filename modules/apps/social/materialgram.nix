{
  pkgs-unstable,
  selfLib,
  ...
}:

let
  materialgramPkg = pkgs-unstable.materialgram;
in
selfLib.mkModule {
  name = "apps.social.materialgram";
  description = "Materialgram Desktop Messaging application";

  hmConfig = {
    home.packages = [ materialgramPkg ];
  };

  nixosConfig =
    { config, ... }:
    {
      my.services.storage.btrfs-nocow-migration.nocowDirectories = [
        ".local/share/materialgram/tdata"
      ];
      my.services.vmtouch.paths = [
        materialgramPkg
        "/home/${config.my.user.name}/.local/share/materialgram"
      ];
    };
}
