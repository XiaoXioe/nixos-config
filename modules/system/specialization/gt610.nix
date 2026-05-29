{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.gt610;
in
{
  options.my.system.gt610 = {
    enable = lib.mkEnableOption "Nvidia GT 610 proprietary driver specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation = {
      "gt610-proprietary".configuration =
        { config, ... }:
        {
          system.nixos.tags = [ "gt610-proprietary" ];

          # Use default LTS kernel (typically 6.6/6.12+), nixpkgs already
          # maintains patches for legacy_390 compilation on modern kernels.
          # Note: Downgrading to 5.15 would fail due to missing vm_flags_set backport
          # yang konflik dengan patch dari nixpkgs.
          boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

          boot.blacklistedKernelModules = [
            "nouveau"
            "i915"
          ];
          services.xserver.videoDrivers = [ "nvidia" ];

          # NVIDIA 390.xx tidak mendukung Wayland dengan baik (terutama pada Fermi/GT 610).
          # Force SDDM and Plasma to use X11.
          services.displayManager.sddm.wayland.enable = lib.mkForce false;
          services.desktopManager.plasma6.enableQt5Integration = true; # For legacy app compatibility if needed

          # Ensure NVIDIA modesetting kernel parameters are active
          # boot.kernelParams = [ "nvidia-drm.modeset=1" ];

          hardware.nvidia = {
            open = false;
            modesetting.enable = true;

            # Sync packages to 5.15 tree using internal config
            package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
          };

          services.xserver = {
            # Force Xorg to ignore failed EDID detection
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
