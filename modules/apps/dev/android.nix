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
      "adbkey_${config.my.user.name}" = {
        key = "adbkey";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.android/adbkey";
        mode = "0400";
      };
      "adbkey_pub_${config.my.user.name}" = {
        key = "adbkey_pub";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.android/adbkey.pub";
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
