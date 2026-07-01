{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.graphics";
  nixosConfig = {

    environment.sessionVariables = {
      MESA_LOADER_DRIVER_OVERRIDE = "crocus";
      LIBVA_DRIVER_NAME = "i965";
      VAAPI_MPEG4_ENABLED = "true";
    };

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

    # DDC/CI monitor control (for ddcutil brightness/input switching)
    hardware.i2c.enable = true;

  };
}
