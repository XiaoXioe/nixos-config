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
            "${config.my.dataBtrfsPath}/bottles"
            "${config.my.dataBtrfsPath}/wine-data"
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
      WINEPREFIX = "${hmOpts.osConfig.my.dataBtrfsPath}/wine-data";
      WINEARCH = "win64";
    };

    systemd.user.tmpfiles.rules = lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) [
      "d ${hmOpts.osConfig.my.dataBtrfsPath}/bottles 0755 - - -"
    ];

    home.file = lib.mkIf (!config.my.apps.gaming.wine.flatpak.enable) (
      selfLib.mkHmSymlinks hmOpts.config {
        ".local/share/bottles" = "${hmOpts.osConfig.my.dataBtrfsPath}/bottles";
      }
    );
  };
}
