{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.packages-vm;
in
{
  options.my.system.packages-vm = {
    enable = selfLib.mkBoolOpt false "Enable Packages for VM";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
      guestfs-tools
    ];
  };
}
