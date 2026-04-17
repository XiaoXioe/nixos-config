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
      mesa-demos
      compsize

      sysbench
      ddcutil
      # kitty.terminfo
      inxi
      jadx
      jdk
      scrcpy
      nil
      nixd
      nix-output-monitor
      nixfmt
      tree
      steam-run
      rsync
      go
      hdparm
      ntfs3g # ntfsfix untuk repair volume NTFS dirty
      usbutils
      pciutils

      #kdePackages.ark # Manajer arsip resmi KDE (pasangan sejoli Dolphin)
      unzip # Mesin untuk file .zip
      zip
      unrar # Mesin untuk file .rar
      p7zip # Mesin untuk file .7z
      nodejs
    ];
  };
}
