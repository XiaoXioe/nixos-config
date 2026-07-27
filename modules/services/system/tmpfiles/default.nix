{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "services.system.tmpfiles";

  options = {
    nocowDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        ".cache/mozilla"
        ".config/zen"
        ".local/share/AyuGramDesktop/tdata"
        "/mnt/data_btrfs/PersistentData/projects/ml/models"
        "/var/lib/vnstat"
        "/nix/var/nix/db"
      ];
      description = ''
        List of directory paths to automatically migrate to Btrfs Copy-on-Write disabled (nocow, +C).
        Can be relative to the user's home directory (e.g. '.cache/mozilla') or absolute paths
        outside home (e.g. '/var/lib/private/ollama').
      '';
    };
  };

  nixosConfig =
    let
      cfg = config.my.services.system.tmpfiles;
    in
    {
      systemd.tmpfiles.rules = [
        # Format: Tipe | Path | Mode | User | Group | Atribut Tambahan

        # Sistem database Nix
        "h /nix/var/nix/db - - - - +C"
        "h /nix/var/nix/temproots - - - - +C"

        # HDD / Virtualisasi
        "h /mnt/data_btrfs/QEMU_Images - - - - +C"
        "h /mnt/data_btrfs/waydroid_images/images13 - - - - +C"
      ]
      ++ (lib.concatLists (
        map (
          dir:
          let
            isAbsolute = lib.hasPrefix "/" dir;
            host_dir = if isAbsolute then dir else "/home/${config.my.user.name}/${dir}";
            persist_dir = "/persist${host_dir}";
          in
          if isAbsolute then
            [
              "h ${host_dir} - - - - +C"
            ]
          else
            [
              # Buat direktori kosong terlebih dahulu dengan owner pengguna agar langsung nocow sejak awal
              "d ${host_dir} 0700 ${config.my.user.name} users - -"
              "d ${persist_dir} 0700 ${config.my.user.name} users - -"
            ]
        ) cfg.nocowDirectories
      ));
    };
}
