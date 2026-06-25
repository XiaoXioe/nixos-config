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
      dataDir = [
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
      aria2
      ncdu
      btdu
      tldr
      bat
      ookla-speedtest
      bmon
      tdl
      gthumb
    ];
  };
}
