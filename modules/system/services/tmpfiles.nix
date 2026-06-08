{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.tmpfiles;
in
{
  options.my.system.services.tmpfiles = {
    enable = lib.mkEnableOption "Rules no CoW on BTRFS" // {
      default = true;
    };
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
