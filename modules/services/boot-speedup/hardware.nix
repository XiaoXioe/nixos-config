{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.services.boot-speedup.enable {
    services.printing.enable = false;
    hardware.bluetooth.enable = lib.mkForce false;
  };
}
