{
  pkgs,
  selfLib,
  ...
}:

let
  marketplaceExts = import ./extensions.nix { inherit pkgs; };
  userSettings = import ./settings.nix { inherit pkgs; };
  flatpakCfg = import ./flatpak.nix { inherit pkgs; };
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
