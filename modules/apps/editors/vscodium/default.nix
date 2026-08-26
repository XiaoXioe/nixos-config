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
    home.packages =
      (selfLib.fetchCachePinned [
        "black"
        "nixd"
        "sqlfluff"
        "clang_tools"
      ])
      ++ (with pkgs; [
        shfmt
        nixfmt
        shellcheck
        nil
        sqlite
        php
      ]);
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
