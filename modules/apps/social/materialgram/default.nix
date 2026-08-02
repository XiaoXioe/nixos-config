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

  nixosConfig = {
    my.services.storage.btrfs-nocow-migration.nocowDirectories = [
      ".local/share/materialgram/tdata"
    ];
  };
}
