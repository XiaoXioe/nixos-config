{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.core.graphics;
in
{
  options.my.system.core.graphics = {
    enable = lib.mkEnableOption "system graphics configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-vaapi-driver
        libvdpau-va-gl
        # vulkan

        vulkan-loader
        vulkan-tools

        intel-media-driver # backup + fitur tambahan
      ];
    };

    environment.systemPackages = with pkgs; [
      libva-utils
    ];

    services.xserver.videoDrivers = [ "modesetting" ];

  };
}
