{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.android";
  description = "Android development tools and ADB keys configuration";

  nixosConfig = {
    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.android 0700 ${config.my.user.name} users - -"
    ];

    sops.secrets = {
      "adbkey" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "android/adbkey.enc";
        path = "/home/${config.my.user.name}/.android/adbkey";
        owner = config.my.user.name;
        mode = "0400";
      };
      "adbkey.pub" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "android/adbkey.pub.enc";
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
