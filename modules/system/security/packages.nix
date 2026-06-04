{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.security.packages;
in
{
  options.my.system.security.packages = {
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
