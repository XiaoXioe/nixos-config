{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.system.android";
  description = "Android development tools and ADB keys configuration";

  nixosConfig = {
    sops.secrets = {
      "adbkey" = {
        format = "binary";
        sopsFile = ./secrets/adbkey.enc;
        path = "/home/${config.my.user.name}/.android/adbkey";
        owner = config.my.user.name;
        mode = "0400";
      };
      "adbkey.pub" = {
        format = "binary";
        sopsFile = ./secrets/adbkey.pub.enc;
        path = "/home/${config.my.user.name}/.android/adbkey.pub";
        owner = config.my.user.name;
        mode = "0444";
      };
    };
  };

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      android-tools
      scrcpy
    ];
  };
}
