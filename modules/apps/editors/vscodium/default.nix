{
  pkgs,
  selfLib,
  ...
}:

let
  marketplaceExts = import ./_extensions { inherit pkgs; };
  userSettings = import ./_settings { inherit pkgs; };
  flatpakCfg = import ./_flatpak { inherit pkgs; };
in
selfLib.mkModule {
  name = "apps.editors.vscodium";
  description = "Vscodium configuration";

  inherit flatpakCfg;

  nixosConfig =
    { config, pkgs, ... }:
    let
      cfg = config.my.apps.editors.vscodium;
      vscodiumPath =
        if cfg.flatpak.enable then "/var/lib/flatpak/app/com.vscodium.codium" else pkgs.vscodium;
    in
    {
      my.services.vmtouch.paths = [
        vscodiumPath
        "/home/${config.my.user.name}/.config/VSCodium"
        "/home/${config.my.user.name}/.vscode-oss"
      ];
    };

  hmConfig = hmOpts: {
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
