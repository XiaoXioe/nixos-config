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
    sops.secrets = builtins.listToAttrs [
      (selfLib.secrets.mkSecret {
        key = "adbkey";
        format = "binary";
        sopsFile = selfLib.secretBinary "android/adbkey.enc";
        path = "/home/${config.my.user.name}/.android/adbkey";
        owner = config.my.user.name;
        mode = "0400";
      })
      (selfLib.secrets.mkSecret {
        key = "adbkey.pub";
        format = "binary";
        sopsFile = selfLib.secretBinary "android/adbkey.pub.enc";
        path = "/home/${config.my.user.name}/.android/adbkey.pub";
        owner = config.my.user.name;
        mode = "0444";
      })
    ];
  };

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      android-tools
      scrcpy
    ];
  };
}
