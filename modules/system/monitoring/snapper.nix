{
  config,
  lib,
  ...
}:

let
  cfg = config.my.services.snapper;

  # Daftar nama user yang dikonfigurasi
  userNames = lib.mapAttrsToList (name: _: name) config.my.users;
in
{
  options.my.services.snapper = {
    enable = lib.mkEnableOption "Snapper backup home data";
  };

  config = lib.mkIf cfg.enable {
    # ===========================================================
    # SNAPPER — Konfigurasi snapshot BTRFS otomatis
    #
    # Arsitektur sistem:
    #   - Subvolume utama: @nixos-persist → dimount di /persist
    #   - Data home user disimpan FISIK di /persist/home/<user>/
    #   - /home/<user>/.config, .ssh, dst. adalah bind-mount dari
    #     /persist/home/<user>/.config, .ssh, dst. (subvolume sama)
    #
    # Mengapa SUBVOLUME = "/persist":
    #   Semua data persisten (termasuk home) ada di satu subvolume
    #   @nixos-persist. Snapshot di /persist menangkap SEMUA data
    #   persisten sekaligus, termasuk isi home, var/lib, etc.
    #
    # Mengapa file terhapus bisa di-restore:
    #   Jika file di /persist/home/<user>/Desktop dihapus, snapshot
    #   older snapshots still contain the file. Restore via:
    #     snapper -c persist rollback <nomor>
    #   atau copy manual dari /persist/.snapshots/<N>/snapshot/
    #
    # PERHATIAN: File yang hanya ada di /home/<user>/ (ephemeral,
    #   not persisted) will NOT be backed up since they are wiped
    #   on every boot. Add to preservation.nix for persistence.
    # ===========================================================
    services.snapper = {
      snapshotInterval = "hourly"; # Jadwal timeline snapshot
      persistentTimer = true; # Execute missed schedules on boot

      configs = {
        # Config utama: snapshot seluruh subvolume @nixos-persist
        # Mencakup: home/, var/lib/, etc/ — semua data yang dipersist
        persist = {
          SUBVOLUME = "/persist";
          ALLOW_USERS = userNames;
          # SYNC_ACL: sync ACL so ALLOW_USERS can read snapshots
          # without sudo (needed for manual list & restore)
          SYNC_ACL = "yes";

          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          # Simpan 3 snapshot per jam (setiap ~20 menit)
          # so recently deleted files can be restored
          TIMELINE_LIMIT_HOURLY = "3";
          TIMELINE_LIMIT_DAILY = "3"; # 1 minggu harian
          TIMELINE_LIMIT_WEEKLY = "2";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
        };

        # Config tambahan: snapshot ephemeral home (/home)
        # Snapshot ini sekarang DI-PERSIST. Anda tidak bisa melakukan
        # rollback penuh pada subvolume home yang di-wipe tiap boot,
        # TAPI Anda bisa meng-copy file yang terhapus dari snapshot lama.
        home = {
          SUBVOLUME = "/home";
          ALLOW_USERS = userNames;
          SYNC_ACL = "yes";

          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7"; # 1 minggu harian
          TIMELINE_LIMIT_WEEKLY = "4"; # 1 bulan mingguan
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };

    # More frequent cleanup schedule to prevent accumulation
    systemd.timers."snapper-cleanup" = {
      timerConfig = {
        OnCalendar = lib.mkForce "*-*-* *:30:00";
      };
    };

    # ===========================================================
    # BTRFS subvolume for .snapshots
    #
    # MUST use "Q" (not "v") because snapper requires
    # .snapshots sebagai BTRFS subvolume, bukan direktori biasa.
    # "Q" = buat subvolume BTRFS jika belum ada
    # "v" = creates a regular directory (WRONG for snapper)
    # ===========================================================
    systemd.tmpfiles.rules = [
      "Q /persist/.snapshots 0750 root root - -"
      "Q /persist/.home-snapshots 0750 root root - -"
    ];

    # Bind-mount so ephemeral home snapshots are stored in persist
    fileSystems."/home/.snapshots" = {
      device = "/persist/.home-snapshots";
      fsType = "none";
      options = [ "bind" ];
      depends = [ "/persist" ];
    };
  };
}
