{
  lib,
  pkgs,
  selfLib,
  config,
  ...
}:
selfLib.mkModule {
  name = "core.kernel.stock";
  description = "Zen Linux Kernel Package Configuration";
  nixosConfig = {
    boot = {
      # Hanya aktif jika modul CachyOS tidak diaktifkan
      kernelPackages = lib.mkIf (!config.my.core.kernel.cachyos.enable or false) pkgs.linuxPackages_zen;
    };
  };
}
