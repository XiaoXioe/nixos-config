{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.virtualisation.packages;
in
{
  options = selfLib.mkNestedEnable "virtualisation.packages";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
    ];
  };
}
