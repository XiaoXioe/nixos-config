{
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  grubfm-efi = pkgs.stdenv.mkDerivation rec {
    pname = "grubfm";
    version = "v7.4.0";

    src = pkgs.fetchurl {
      url = "https://github.com/a1ive/grub2-filemanager/releases/download/${version}/grubfm-en_US.7z";
      hash = "sha256-J2TDaqdBzTY9kqCQ3Ra6pQ/x83a+Q9XBf6Ihc83mFpI=";
    };

    nativeBuildInputs = [ pkgs.p7zip ];

    unpackPhase = ''
      7z x $src
    '';

    installPhase = ''
      mkdir -p $out

      cp grubfmx64.efi $out/grubfmx64.efi
    '';
  };

in
selfLib.mkModule {
  name = "core.bootloader";
  nixosConfig = {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      theme = pkgs.catppuccin-grub.override { flavor = "macchiato"; };

      extraEntries = ''
        menuentry "Grub2 File Manager" --class efi {
          search --no-floppy --fs-uuid --set=root CF4A-0A6F
          chainloader /EFI/grubfm/grubfmx64.efi
        }
      '';
    };

    system.activationScripts.setupGrubFM = {
      text = ''
        mkdir -p /boot/efi/EFI/grubfm
        cp -f ${grubfm-efi}/grubfmx64.efi /boot/efi/EFI/grubfm/grubfmx64.efi
      '';
      deps = [ ];
    };
  };
}
