{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.bootloader;
in
{
  options.my.system.bootloader = {
    enable = selfLib.mkBoolOpt false "system bootloader configuration";
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };
}
