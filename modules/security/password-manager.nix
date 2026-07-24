{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "security.password-manager";
  description = "Password manager desktop applications (Bitwarden & Proton Pass)";

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

    "me.proton.Pass" = {
      enable = true;
      binName = "proton-pass";
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
          host = ".config/Proton Pass";
          guest = "config/Proton Pass";
        }
      ];
      nativePkgs = pkgs.proton-pass;
    };
  };
}
