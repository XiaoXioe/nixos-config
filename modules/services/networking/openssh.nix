{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.services.networking.openssh;
in
{
  options = selfLib.mkNestedEnable "services.networking.openssh";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sshfs
    ];
    services.openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true; # buka port 22 di firewall
      # listenAddresses default = all interfaces (LAN accessible)
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        AllowUsers = lib.mapAttrsToList (name: _: name) config.my.users;
      };
    };
  };
}
