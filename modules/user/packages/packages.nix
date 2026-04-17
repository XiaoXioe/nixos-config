{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.packages;
in
{
  options.my.user.packages = {
    enable = selfLib.mkBoolOpt false "user-specific packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [

      ripgrep
      jq
      fzf
      # fish
      fastfetch
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
