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
    };
  };
}
