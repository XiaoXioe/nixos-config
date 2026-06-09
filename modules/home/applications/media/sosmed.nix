{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.apps.media.sosmed;
in
{
  options.my.user.apps.media.sosmed = {
    enable = lib.mkEnableOption "Sosmed package for users";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # bitwarden-desktop
      # ayugram-desktop
      # materialgram
      ente-auth
      tradingview
      signal-desktop
      discord
      # zapzap
    ];
  };
}
