{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.bootSpeedup;
  inherit (lib) mkIf mkForce;
in
{
  options.my.system.services.bootSpeedup.hardware = {
    enable = lib.mkEnableOption "disable printing and bluetooth" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.hardware.enable) {
    services.printing.enable = false;
    hardware.bluetooth.enable = mkForce false;
  };
}
