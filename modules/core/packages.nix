{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.core.packages;
in
{
  options = selfLib.mkNestedEnable "core.packages";

  config = lib.mkIf cfg.enable {
    programs = {
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
      dconf.enable = true;
      fuse.userAllowOther = true;
    };

    environment.systemPackages = with pkgs; [
      wget
      iotop-c
      fd
      nethogs
      nh
      unzip
      intel-gpu-tools
      compsize

      ddcutil
      scrcpy
      rsync
      go
      usbutils
      pciutils

      unzip # Archive handler for .zip
      zip
      unrar # Archive handler for .rar
      p7zip # Archive handler for .7z
    ];
  };
}
