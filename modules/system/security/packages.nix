{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.packages-security;
in
{
  options.my.system.packages-security = {
    enable = lib.mkEnableOption "Enable packages for security";
  };

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
