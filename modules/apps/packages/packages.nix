{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.packages.general";
  description = "user-specific packages";

  hmConfig = {
    home.packages = with pkgs; [ ripgrep jq aria2 ncdu btdu tldr bat ookla-speedtest bmon tdl ];
  };
}
