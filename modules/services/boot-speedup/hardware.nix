{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.boot-speedup;
  inherit (lib) mkIf mkForce;
in
{
  options = selfLib.mkNestedEnable "services.boot-speedup.hardware";

  config = mkIf (cfg.enable && cfg.hardware.enable) {
    services.printing.enable = false;
    hardware.bluetooth.enable = mkForce false;
  };
}
