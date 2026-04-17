{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.services.openssh;
in
{
  options.my.services.openssh = {
    enable = selfLib.mkBoolOpt false "openssh service";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sshfs
    ];
    services.openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true; # buka port 22 di firewall
      # listenAddresses default = semua interface (LAN bisa akses)
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        AllowUsers = lib.mapAttrsToList (name: _: name) config.my.users;
      };
    };
  };
}
