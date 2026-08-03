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

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      black
      shfmt
      nixfmt
      ruff
      shellcheck
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
