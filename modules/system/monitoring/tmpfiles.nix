{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.tmpfiles;
in
{
  options.my.services.tmpfiles = {
    enable = selfLib.mkBoolOpt false "Rules no CoW on BTRFS";
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      # Format: Tipe | Path | Mode | User | Group | Atribut Tambahan

      # Mematikan CoW untuk folder cache Nix
      "h /home/${config.my.user.name}/.cache/nix - - - - +C"
      "h /nix/var/nix/db - - - - +C"
      "H /nix/var/nix/db - - - - +C" # Gunakan 'H' besar agar file di dalamnya ikut terkena +C
      "h /nix/var/nix/temproots - - - - +C"

      # HDD
      "h /mnt/data_btrfs/QEMU_Images - - - - +C"
      "H /mnt/data_btrfs/QEMU_Images - - - - +C"
      # "H /mnt/data_btrfs/waydroid_data - - - - +C"
      "H /mnt/data_btrfs/waydroid_images/images11 - - - - +C"
    ];
  };
}
