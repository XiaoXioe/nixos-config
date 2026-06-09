{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.apps.packages.packages;
in
{
  options.my.user.apps.packages.packages = {
    enable = lib.mkEnableOption "user-specific packages";
  };

  config = lib.mkIf cfg.enable {
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
