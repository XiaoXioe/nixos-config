{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup.hardware";
  nixosConfig = lib.mkIf config.my.services.boot-speedup.enable {
    services.printing.enable = false;
    hardware.bluetooth.enable = lib.mkForce false;
  };
}
