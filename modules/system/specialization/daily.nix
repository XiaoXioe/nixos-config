{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.daily;
in
{
  options.my.system.daily = {
    enable = lib.mkEnableOption "Daily drive specialisation";
  };

  config = lib.mkIf cfg.enable {
    specialisation."daily-mode".configuration = {
      networking.hostName = lib.mkForce "nixos-daily";

      my.system.security-tools-system.enable = lib.mkForce false;
    };
  };
}
