{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.tor-browser";
  description = "Tor Browser configuration";

  flatpakCfg = {
    "org.torproject.torbrowser-launcher" = {
      enable = true;

      overrides = {
        Context = {
          filesystems = [
            "xdg-run/psd" # Profile Sync Daemon tmpfs
          ];
        };
      };

      # Symlinks to keep data persistent and synced between native and Flatpak
      symlinks = [
        {
          host = ".local/share/torbrowser";
          guest = "data/torbrowser";
        }
      ];

      # Native package fallback if Flatpak is disabled
      nativePkgs = pkgs.tor-browser;
    };
  };
}
