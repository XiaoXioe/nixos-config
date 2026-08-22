{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.discord;

  discordNative = (selfLib.mkNativeApp pkgs) {
    name = "discord";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "discord";
    execPath = "usr/bin/discord";
    binName = "discord";
    extraPkgs = [
      pkgs.zenity
      pkgs.curl
    ];
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
    extraUnwrappedInstall = ''
      if [ -f "$out/opt/discord/usr/share/discord/updater_bootstrap" ]; then
        chmod +x "$out/opt/discord/usr/share/discord/updater_bootstrap"
        ln -sf "$out/opt/discord/usr/share/discord/updater_bootstrap" "$out/opt/discord/usr/bin/updater_bootstrap"
        sed -i "s|/usr/share/discord/updater_bootstrap|$out/opt/discord/usr/share/discord/updater_bootstrap|g" "$out/opt/discord/usr/bin/discord"
        sed -i "s|/opt/discord/updater_bootstrap|$out/opt/discord/usr/share/discord/updater_bootstrap|g" "$out/opt/discord/usr/bin/discord"
      fi
    '';
  };
in
selfLib.mkModule {
  name = "apps.social.discord";
  description = "Discord communication desktop application";

  hmConfig = {
    home.packages = [ discordNative ];
  };
}
