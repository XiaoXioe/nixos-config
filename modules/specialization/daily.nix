{
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "specialization.daily";

  nixosConfig = {
    specialisation."daily-mode".configuration = {
      networking.hostName = lib.mkForce "nixos-daily";
      # my.security.tools.enable = lib.mkForce false; # Assume security tools refactor later
    };
  };
}
