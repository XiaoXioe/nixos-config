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
      enable = true;
      binName = "bitwarden";
      symlinks = [
        {
          host = ".config/Bitwarden";
          guest = "config/Bitwarden";
        }
      ];
      nativePkgs = pkgs.bitwarden-desktop;
    };

    "org.gnome.gThumb" = {
      enable = true;
      nativePkgs = pkgs.gthumb;
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
