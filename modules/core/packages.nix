{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.packages";

  nixosConfig = {
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

      dconf.enable = true;
      fuse.userAllowOther = true;
    };

    environment.systemPackages = with pkgs; [
      android-tools
      exiftool
      oniux
      wget
      iotop-c
      intel-gpu-tools
      compsize

      ddcutil
      scrcpy
      rsync
      go
      usbutils
      pciutils

      killall
      inetutils
    ];
  };
}
