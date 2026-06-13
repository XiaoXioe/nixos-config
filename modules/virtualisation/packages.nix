{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "virtualisation.packages";

  nixosConfig = {
    environment.systemPackages = with pkgs; [
      qemu
    ];
  };
}
