{
  pkgs,
  selfLib,
  ...
}:

let
  marketplaceExts = import ./_extensions { inherit pkgs; };
  userSettings = import ./_settings { inherit pkgs; };
  appInfo = selfLib.appVersions.vscodium;

  vscodiumNative = (selfLib.mkNativeApp pkgs) {
    name = "codium";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "vscodium";
    execPath = "usr/share/codium/bin/codium";
    binName = "codium";
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
    };
    extraUnwrappedInstall = ''
      if [ -f "$out/opt/codium/usr/share/codium/bin/codium" ]; then
        sed -i "/ELECTRON=/iVSCODE_PATH='$out/opt/codium/usr/share/codium'" "$out/opt/codium/usr/share/codium/bin/codium"
        chmod +x "$out/opt/codium/usr/share/codium/bin/codium"
        chmod +x "$out/opt/codium/usr/share/codium/codium"
      fi
    '';
  };
in
selfLib.mkModule {
  name = "apps.editors.vscodium";
  description = "Vscodium configuration";

  nixosConfig =
    { config, ... }:
    {
      my.services.vmtouch.paths = [
        vscodiumNative
        "/home/${config.my.user.name}/.config/VSCodium"
        "/home/${config.my.user.name}/.vscode-oss"
      ];
    };

  hmConfig = {
    home.packages = with pkgs; [
      black
      shfmt
      nixfmt
      ruff
      shellcheck
      nil
      nixd
      sqlite
      sqlfluff
      php
      clang-tools
    ];
    programs.vscodium = {
      enable = true;
      package = vscodiumNative;
      argvSettings = {
        ignore-gpu-blocklist = true;
        enable-crash-reporter = false;
        disable-gpu-compositing = false;
      };
      mutableExtensionsDir = false;
      profiles.default = {
        extensions = marketplaceExts;
        inherit userSettings;
      };
    };
  };
}
