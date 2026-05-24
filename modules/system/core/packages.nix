{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.packages;
in
{
  options.my.system.packages = {
    enable = selfLib.mkBoolOpt false "Enable common system packages";
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
        # Mengaktifkan syntax highlighting
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
      bleachbit
      nh
      unzip
      intel-gpu-tools
      compsize

      ddcutil
      jdk
      scrcpy
      nixfmt
      rsync
      go
      usbutils
      pciutils

      unzip # Mesin untuk file .zip
      zip
      unrar # Mesin untuk file .rar
      p7zip # Mesin untuk file .7z
      nodejs
      php
    ];
  };
}
