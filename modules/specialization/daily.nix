{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.specialization.daily;
in
{
  options = selfLib.mkNestedEnable "specialization.daily";

  config = lib.mkIf cfg.enable {
    specialisation."daily-mode".configuration = {
      networking.hostName = lib.mkForce "nixos-daily";
      my.security.tools.enable = lib.mkForce false; # Assume security tools refactor later
    };
  };
}
