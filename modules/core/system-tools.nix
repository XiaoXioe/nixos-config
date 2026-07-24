{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.system-tools";
  description = "Essential system-level CLI administration tools and base program settings";

  nixosConfig = {
    programs = {
      nano = {
        syntaxHighlight = true;
        nanorc = ''
          set linenumbers
          set tabsize 4
          set tabstospaces
          set autoindent
          set mouse
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
