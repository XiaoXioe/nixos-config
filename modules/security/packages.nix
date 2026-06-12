{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.security.packages;
in
{
  options = selfLib.mkNestedEnable "security.packages";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
      openresolv
      killall
      inetutils
      #      sops

    ];
  };
}
