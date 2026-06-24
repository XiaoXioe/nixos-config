{
  pkgs,
  selfLib,
  config,
  ...
}:

selfLib.mkApp {
  name = "apps.gaming.wine";
  description = "Wine and Bottles compatibility layer";

  flatpak = {
    appId = "com.usebottles.bottles";
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
  };

  native = {
    package = pkgs.bottles;
  };

  hmProgram = null;

  hmConfig =
    hmArgs@{ pkgs, lib, ... }:
    {
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

      home.file.".local/share/bottles".source =
        hmArgs.config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/bottles";
    };
}
