{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.kernel;
in
{
  options.my.system.kernel = {
    enable = lib.mkEnableOption "Kernel managment";
  };

  config = lib.mkIf cfg.enable {
    specialisation = {
      zen-kernel.configuration = {
        system.nixos.tags = [ "kernel-zen" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen; # Use Zen kernel
      };
    };
  };
}
