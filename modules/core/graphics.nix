{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.graphics";
  nixosConfig = {
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
