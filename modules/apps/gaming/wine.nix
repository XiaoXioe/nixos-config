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

    home.activation.setupBottlesSymlinks = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "$HOME/.local/share/bottles" ] && [ ! -L "$HOME/.local/share/bottles" ]; then
        rm -rf "$HOME/.local/share/bottles"
      fi
      mkdir -p "$HOME/.local/share"
      mkdir -p "/mnt/data_btrfs/bottles"
      ln -sfn "/mnt/data_btrfs/bottles" "$HOME/.local/share/bottles"
    '';
  };
}
