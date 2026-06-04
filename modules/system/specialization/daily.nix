{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.specialisation.daily;
in
{
  options.my.system.specialisation.daily = {
    enable = lib.mkEnableOption "Daily drive specialisation";
  };

  config = lib.mkIf cfg.enable {
    specialisation."daily-mode".configuration = {
      networking.hostName = lib.mkForce "nixos-daily";

      my.system.security.tools.enable = lib.mkForce false;
    };
  };
}
