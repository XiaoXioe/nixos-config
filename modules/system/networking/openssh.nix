{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.openssh;
in
{
  options.my.services.openssh = {
    enable = lib.mkEnableOption "openssh service";
  };

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
