{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.sosmed;
in
{
  options.my.user.sosmed = {
    enable = selfLib.mkBoolOpt false "Sosmed package for users";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden-desktop
      ayugram-desktop
      materialgram
      ente-auth
      tradingview
      signal-desktop
      spotdl
      discord
      # zapzap
    ];
  };
}
