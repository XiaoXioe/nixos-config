{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.packages-security;
in
{
  options.my.system.packages-security = {
    enable = selfLib.mkBoolOpt false "Enable packages for security";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vulnix
      wireguard-tools
      iproute2
      openresolv
      killall
      inetutils
      appimage-run
      sops

    ];
  };
}
