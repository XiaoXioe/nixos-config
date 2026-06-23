{
  selfLib,
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    (selfLib.mkModule {
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
    })

    (selfLib.mkApp {
      name = "apps.media.ayugram";
      description = "AyuGram Desktop Telegram Client";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.enable;
          description = "Enable AyuGram client";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.flatpak.enable;
          description = "Whether to use Flatpak for AyuGram instead of the native package.";
        };
      };
      native = {
        package = pkgs.ayugram-desktop;
      };
      flatpak = {
        appId = "com.ayugram.desktop";
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
      };
    })

    (selfLib.mkApp {
      name = "apps.media.discord";
      description = "Discord chat client";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.enable;
          description = "Enable Discord client";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.flatpak.enable;
          description = "Whether to use Flatpak for Discord instead of the native package.";
        };
      };
      flatpak = {
        appId = "com.discordapp.Discord";
        symlinks = [
          {
            host = ".config/discord";
            guest = "config/discord";
          }
        ];
      };
      native = {
        package = pkgs.discord;
      };
    })

    (selfLib.mkApp {
      name = "apps.media.signal";
      description = "Signal Private Messenger";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.enable;
          description = "Enable Signal client";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.flatpak.enable;
          description = "Whether to use Flatpak for Signal instead of the native package.";
        };
      };
      flatpak = {
        appId = "org.signal.Signal";
        symlinks = [
          {
            host = ".config/Signal";
            guest = "config/Signal";
          }
        ];
      };
      native = {
        package = pkgs.signal-desktop;
      };
    })

    (selfLib.mkApp {
      name = "apps.media.tradingview";
      description = "TradingView Desktop App";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.enable;
          description = "Enable TradingView app";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.flatpak.enable;
          description = "Whether to use Flatpak for TradingView instead of the native package.";
        };
      };
      flatpak = {
        appId = "com.tradingview.tradingview";
        symlinks = [
          {
            host = ".config/TradingView";
            guest = "config/TradingView";
          }
        ];
      };
      native = {
        package = pkgs.tradingview;
      };
    })

    (selfLib.mkApp {
      name = "apps.media.ente-auth";
      description = "Ente Auth 2FA Client";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.enable;
          description = "Enable Ente Auth app";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.sosmed.flatpak.enable;
          description = "Whether to use Flatpak for Ente Auth instead of the native package.";
        };
      };
      flatpak = {
        appId = "io.ente.auth";
        symlinks = [
          {
            host = ".local/share/io.ente.auth";
            guest = "data/io.ente.auth";
          }
        ];
      };
      native = {
        package = pkgs.ente-auth;
      };
    })
  ];
}
