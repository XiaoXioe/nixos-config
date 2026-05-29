{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.packages;
in
{
  options.my.user.packages = {
    enable = lib.mkEnableOption "user-specific packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      boxbuddy
      distrobox

      ripgrep
      jq
      aria2
      ncdu
      btdu
      tldr
      bat
      ookla-speedtest
      bmon
      qbittorrent-enhanced
      tdl

    ];
  };
}
