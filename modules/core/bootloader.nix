{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  grubfm-efi = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "grubfm";
    version = "v7.4.0";

    src = pkgs.fetchurl {
      url = "https://github.com/a1ive/grub2-filemanager/releases/download/${finalAttrs.version}/grubfm-en_US.7z";
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
  });

  efiDevice = config.fileSystems."/boot/efi".device or "";
  efiUuid = lib.removePrefix "/dev/disk/by-uuid/" efiDevice;
in
selfLib.mkModule {
  name = "core.bootloader";
  nixosConfig = {
    assertions = [
      {
        assertion = config.fileSystems ? "/boot/efi";
        message = "Partisi /boot/efi harus dikonfigurasi dalam fileSystems agar bootloader dapat diinisialisasi.";
      }
      {
        assertion = lib.hasPrefix "/dev/disk/by-uuid/" efiDevice;
        message = "fileSystems.\"/boot/efi\".device harus berformat /dev/disk/by-uuid/<UUID> agar grubfm bisa menemukan partisi EFI.";
      }
    ];

    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = false;
        theme = pkgs.catppuccin-grub.override { flavor = "macchiato"; };

        extraEntries = ''
          menuentry "Grub2 File Manager" --class efi {
            # UUID partisi EFI diambil otomatis dari fileSystems."/boot/efi".device
            search --no-floppy --fs-uuid --set=root ${efiUuid}
            chainloader /EFI/grubfm/grubfmx64.efi
          }
        '';

        extraFiles = {
          "efi/EFI/grubfm/grubfmx64.efi" = "${grubfm-efi}/grubfmx64.efi";
        };
      };
    };
  };
}
