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
      exiftool
      oniux
      wget
      iotop-c

      ddcutil
      rsync
      usbutils
      pciutils
      compsize

      killall
      inetutils
    ];
  };
}
