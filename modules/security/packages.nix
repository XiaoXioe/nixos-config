{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "security.packages";

  nixosConfig = {
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
