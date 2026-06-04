{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.virtualisation.packages;
in
{
  options.my.system.virtualisation.packages = {
    enable = lib.mkEnableOption "Enable Packages for VM";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
      # guestfs-tools
    ];
  };
}
