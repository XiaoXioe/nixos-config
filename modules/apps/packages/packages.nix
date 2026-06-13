{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.packages.general";
  description = "Base packages for user";

  hmConfig = {
    home.packages = with pkgs; [
      ripgrep
      jq
      aria2
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
