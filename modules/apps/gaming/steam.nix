{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.steam";
  description = "Steam client and hardware configuration";

  preservation = {
    userDirectories = [ ".steam" ];
  };

  nixosConfig = {
    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
