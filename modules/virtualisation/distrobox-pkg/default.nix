{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.virtualisation.distrobox-pkg;
  dboxPkgPackage = import ./package.nix { inherit pkgs lib selfLib; };
in
selfLib.mkModule {
  name = "virtualisation.distrobox-pkg";
  description = "Native host CLI tool and package manager shortcuts for Distrobox containers";

  options = {
    enableShortcuts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable native shell aliases (dbox, dbox-apt, dbox-pacman, dbox-dnf, dbox-apk, dbox-zypper, dbox-xbps).";
    };
  };

  nixosConfig = {
    environment.systemPackages = [
      dboxPkgPackage
    ];

    # Native NixOS shell aliases across all shells (Fish, Bash, Zsh)
    environment.shellAliases = lib.mkIf cfg.enableShortcuts {
      dbox = "dbox-pkg";
      dbox-apt = "dbox-pkg apt";
      dbox-pacman = "dbox-pkg pacman";
      dbox-dnf = "dbox-pkg dnf";
      dbox-apk = "dbox-pkg apk";
      dbox-zypper = "dbox-pkg zypper";
      dbox-xbps = "dbox-pkg xbps-install";
    };
  };
}
