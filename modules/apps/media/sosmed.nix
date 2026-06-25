{
  selfLib,
  pkgs,
  lib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.sosmed";
  description = "Social Media applications bundle";
  options = {
    flatpak = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Flatpak for all social media applications by default.";
      };
    };
  };

  flatpakCfg = {
    "com.ayugram.desktop" = {
      enable = true;
      sha256 = "0jk3f1dsb2jb77rk1a8rm5jnh6315mhxf1fnm70vgwmn1a2xd6rp";
      bundle = "${pkgs.fetchurl {
        url = "https://github.com/0FL01/AyuGramDesktop-flatpak/releases/download/flatpak-v6.7.8-20260604235309/ayugram-desktop-6.7.8.flatpak";
        sha256 = "0jk3f1dsb2jb77rk1a8rm5jnh6315mhxf1fnm70vgwmn1a2xd6rp";
      }}";
      symlinks = [
        {
          host = ".local/share/AyuGramDesktop";
          guest = "data/AyuGramDesktop";
        }
      ];
      nativePkgs = pkgs.ayugram-desktop;
    };

    "com.discordapp.Discord" = {
      enable = true;
      symlinks = [
        {
          host = ".config/discord";
          guest = "config/discord";
        }
      ];
      nativePkgs = pkgs.discord;
    };

    "org.signal.Signal" = {
      enable = true;
      symlinks = [
        {
          host = ".config/Signal";
          guest = "config/Signal";
        }
      ];
      nativePkgs = pkgs.signal-desktop;
    };

    "com.tradingview.tradingview" = {
      enable = true;
      symlinks = [
        {
          host = ".config/TradingView";
          guest = "config/TradingView";
        }
      ];
      nativePkgs = pkgs.tradingview;
    };

    "io.ente.auth" = {
      enable = true;
      symlinks = [
        {
          host = ".local/share/io.ente.auth";
          guest = "data/enteauth";
        }
      ];
      nativePkgs = pkgs.ente-auth;
    };
  };
}
