{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.graphics;
in
{
  options.my.system.graphics = {
    enable = selfLib.mkBoolOpt false "system graphics configuration";
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
