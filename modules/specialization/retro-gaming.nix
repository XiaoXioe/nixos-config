{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.specialization.retro-gaming;
in
{
  options = selfLib.mkNestedEnable "specialization.retro-gaming";

  config = lib.mkIf cfg.enable {
    specialisation."retro-mode".configuration = {
      system.nixos.tags = [ "retro-gaming-ps" ];
      environment.systemPackages = with pkgs; [
        retroarch-full
        libretro.swanstation
        ppsspp
        pcsx2
        antimicrox
      ];

      hardware.uinput.enable = true;
      services.udev.packages = [ pkgs.game-devices-udev-rules ];
      programs.gamemode.enable = true;
      powerManagement.cpuFreqGovernor = lib.mkForce "performance";
      services.thermald.enable = true;
    };
  };
}
