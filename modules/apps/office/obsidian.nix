{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.obsidian;

  obsidianNative = (selfLib.mkNativeApp pkgs) {
    name = "obsidian";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "obsidian";
    execPath = "opt/Obsidian/obsidian";
    binName = "obsidian";
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };
in
selfLib.mkModule {
  name = "apps.office.obsidian";
  description = "Obsidian Markdown note-taking and knowledge base application";

  hmConfig = {
    home.packages = [ obsidianNative ];
  };
}
