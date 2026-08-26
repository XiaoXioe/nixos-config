{
  pkgs,
  selfLib,
  ...
}:

let
  marketplaceExts = import ./_extensions { inherit pkgs; };
  userSettings = import ./_settings { inherit pkgs; };
  vscodiumPkg = selfLib.fetchCachePinned pkgs "vscodium";
in
selfLib.mkModule {
  name = "apps.editors.vscodium";
  description = "Vscodium configuration";

  nixosConfig =
    { config, ... }:
    {
      my.services.vmtouch.paths = [
        vscodiumPkg
        "/home/${config.my.user.name}/.config/VSCodium"
        "/home/${config.my.user.name}/.vscode-oss"
      ];
    };

  hmConfig = {
    home.packages = with pkgs; [
      black
      shfmt
      nixfmt
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
      package = vscodiumPkg;
      argvSettings = {
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
