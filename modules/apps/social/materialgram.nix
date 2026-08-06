{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.social.materialgram";
  description = "Materialgram Desktop Messaging application";

  flatpakCfg = {
    "io.github.kukuruzka165.materialgram" = {
      enable = true;
      overrides = {
        Context = {
          filesystems = [
            "~/.local/share/materialgram:rw"
            "/nix/store:ro"
          ];
        };
      };
      symlinks = [
        {
          host = ".local/share/materialgram";
          guest = "data/materialgram";
        }
      ];
      nativePkgs = pkgs.materialgram;
    };
  };

  nixosConfig =
    { config, pkgs, ... }:
    let
      cfg = config.my.apps.social.materialgram;
      materialgramPath =
        if cfg.flatpak.enable then
          "/var/lib/flatpak/app/io.github.kukuruzka165.materialgram"
        else
          pkgs.materialgram;
    in
    {
      my.services.storage.btrfs-nocow-migration.nocowDirectories = [
        ".local/share/materialgram/tdata"
      ];
      my.services.vmtouch.paths = [
        materialgramPath
        "/home/${config.my.user.name}/.local/share/materialgram"
      ];
    };
}
