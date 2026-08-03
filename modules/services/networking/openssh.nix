{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.openssh";

  nixosConfig = {
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
        PasswordAuthentication = false;
        AllowUsers = [ config.my.user.name ];
      };
    };
  };
}
