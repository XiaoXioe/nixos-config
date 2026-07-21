{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.packages.general";
  description = "Base packages for user";

  flatpakCfg = {
    "com.bitwarden.desktop" = {
      enable = false;
      binName = "bitwarden";
      overrides = {
        Context = {
          sockets = [
            "wayland"
            "fallback-x11"
          ];
          shares = [ "ipc" ];
        };
        Environment = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
        SessionBus = {
          talk = [
            "org.freedesktop.portal.Failsafe"
            "org.freedesktop.portal.Secret"
            "org.freedesktop.portal.Desktop"
          ];
        };
      };
      symlinks = [
        {
          host = ".config/Bitwarden";
          guest = "config/Bitwarden";
        }
      ];
      nativePkgs = pkgs.bitwarden-desktop;
    };
  };

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      ripgrep
      fd
      jq
      ncdu
      btdu
      tldr
      bat
      ookla-speedtest
      bmon
      tdl
    ];
  };
}
