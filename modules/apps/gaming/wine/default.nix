{
  pkgs,
  selfLib,
  lib,
  config,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.wine";
  description = "Wine and Bottles compatibility layer";

  flatpakCfg = {
    "com.usebottles.bottles" = {
      enable = true;
      overrides = {
        Context = {
          filesystems = [
            "/mnt/data_btrfs/bottles"
            "/mnt/data_btrfs/wine-data"
          ];
        };
      };
      symlinks = [
        {
          host = ".local/share/bottles";
          guest = "data/bottles";
        }
      ];
      nativePkgs = pkgs.bottles;
    };
  };

  hmConfig = hmOpts: {
    home.packages =
      with pkgs;
      lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) [
        wineWow64Packages.stable
        winetricks
      ];

    home.sessionVariables = lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) {
      WINEDLLOVERRIDES = "winemenubuilder.exe=d";
      WINEPREFIX = "/mnt/data_btrfs/wine-data";
      WINEARCH = "win64";
    };

    systemd.user.tmpfiles.rules = lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) [
      "d /mnt/data_btrfs/bottles 0755 - - -"
    ];

    home.file = lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) {
      ".local/share/bottles".source =
        hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/bottles";
    };
  };
}
