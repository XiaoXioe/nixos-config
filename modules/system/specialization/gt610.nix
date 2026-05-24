{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.gt610;
in
{
  options.my.system.gt610 = {
    enable = selfLib.mkBoolOpt false "Nvidia GT 610 proprietary driver specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation = {
      "gt610-proprietary".configuration =
        { config, ... }:
        {
          system.nixos.tags = [ "gt610-proprietary" ];

          # Gunakan LTS Kernel default (biasanya 6.6/6.12+), karena nixpkgs sudah
          # me-maintain patch agar legacy_390 bisa di-compile di kernel modern.
          # Catatan: Downgrade ke 5.15 justru akan gagal build karena backport vm_flags_set
          # yang konflik dengan patch dari nixpkgs.
          boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

          boot.blacklistedKernelModules = [
            "nouveau"
            "i915"
          ];
          services.xserver.videoDrivers = [ "nvidia" ];

          # NVIDIA 390.xx tidak mendukung Wayland dengan baik (terutama pada Fermi/GT 610).
          # Paksa SDDM dan Plasma untuk menggunakan X11.
          services.displayManager.sddm.wayland.enable = lib.mkForce false;
          services.desktopManager.plasma6.enableQt5Integration = true; # Untuk kompatibilitas app lama jika perlu

          # Pastikan kernel parameter untuk modesetting NVIDIA aktif
          # boot.kernelParams = [ "nvidia-drm.modeset=1" ];

          hardware.nvidia = {
            open = false;
            modesetting.enable = true;

            # Sinkronisasi package eksplisit ke tree 5.15 menggunakan internal config
            package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
          };

          services.xserver = {
            # Paksa Xorg untuk mengabaikan deteksi EDID yang gagal
            deviceSection = ''
              Option "AllowEmptyInitialConfiguration" "true"
              Option "UseDisplayDevice" "DFP"
            '';
            screenSection = ''
              # Tetapkan resolusi dan refresh rate secara paksa
              Option "metamodes" "1920x1080_60 +0+0"
              Option "ModeValidation" "AllowNonEdidModes"
            '';
          };
        };
    };
  };
}
