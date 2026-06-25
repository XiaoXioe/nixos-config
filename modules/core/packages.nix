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

    services.flatpak = {
      packages = [
        "com.protonvpn.www"
      ];
    };

    environment.systemPackages = with pkgs; [
      android-tools
      exiftool
      oniux
      wget
      iotop-c
      nethogs
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
