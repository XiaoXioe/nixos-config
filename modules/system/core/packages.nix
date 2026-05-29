{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.packages;
in
{
  options.my.system.packages = {
    enable = lib.mkEnableOption "Enable common system packages";
  };

  config = lib.mkIf cfg.enable {
    hardware.steam-hardware.enable = true;

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };

      nano = {
        # Enable syntax highlighting
        syntaxHighlight = true;

        nanorc = ''
          set linenumbers
          set tabsize 4
          set tabstospaces
          set autoindent
          set mouse
          # set smooth
        '';
      };

      fish.enable = true;
      fuse.userAllowOther = true;
    };

    environment.systemPackages = with pkgs; [
      wget
      iotop-c
      fd
      python3
      nethogs
      nh
      unzip
      intel-gpu-tools
      compsize
      comma

      ddcutil
      jdk
      scrcpy
      nixfmt
      rsync
      go
      usbutils
      pciutils

      unzip # Archive handler for .zip
      zip
      unrar # Archive handler for .rar
      p7zip # Archive handler for .7z
      nodejs
      php
    ];
  };
}
