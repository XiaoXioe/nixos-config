{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.daily;
in
{
  options.my.system.daily = {
    enable = selfLib.mkBoolOpt false "Daily drive specialisation";
  };

  config = lib.mkIf cfg.enable {
    specialisation."daily-mode".configuration = {
      networking.hostName = lib.mkForce "nixos-daily";

      my.system.security-tools-system.enable = lib.mkForce false;
    };
  };
}
