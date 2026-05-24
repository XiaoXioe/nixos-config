{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.snapper;

  # Daftar nama user yang dikonfigurasi
  userNames = lib.mapAttrsToList (name: _: name) config.my.users;
in
{
  options.my.services.snapper = {
    enable = selfLib.mkBoolOpt false "Snapper backup home data";
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
    #   lama masih menyimpan file tersebut. Restore via:
    #     snapper -c persist rollback <nomor>
    #   atau copy manual dari /persist/.snapshots/<N>/snapshot/
    #
    # PERHATIAN: File yang hanya ada di /home/<user>/ (ephemeral,
    #   bukan di-persist) TIDAK akan di-backup karena di-wipe
    #   setiap boot. Tambahkan ke preservation.nix agar persisten.
    # ===========================================================
    services.snapper = {
      snapshotInterval = "hourly"; # Jadwal timeline snapshot
      persistentTimer = true; # Eksekusi jadwal yang terlewat saat boot

      configs = {
        # Config utama: snapshot seluruh subvolume @nixos-persist
        # Mencakup: home/, var/lib/, etc/ — semua data yang dipersist
        persist = {
          SUBVOLUME = "/persist";
          ALLOW_USERS = userNames;
          # SYNC_ACL: sinkronkan ACL agar ALLOW_USERS bisa read snapshot
          # tanpa sudo (diperlukan untuk list & restore manual)
          SYNC_ACL = "yes";

          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          # Simpan 3 snapshot per jam (setiap ~20 menit)
          # agar bisa mengembalikan file yang baru dihapus
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

    # Jadwal cleanup lebih sering agar tidak menumpuk
    systemd.timers."snapper-cleanup" = {
      timerConfig = {
        OnCalendar = lib.mkForce "*-*-* *:30:00";
      };
    };

    # ===========================================================
    # BTRFS subvolume untuk .snapshots
    #
    # WAJIB menggunakan "Q" (bukan "v") karena snapper memerlukan
    # .snapshots sebagai BTRFS subvolume, bukan direktori biasa.
    # "Q" = buat subvolume BTRFS jika belum ada
    # "v" = hanya buat direktori biasa (SALAH untuk snapper)
    # ===========================================================
    systemd.tmpfiles.rules = [
      "Q /persist/.snapshots 0750 root root - -"
      "Q /persist/.home-snapshots 0750 root root - -"
    ];

    # Bind-mount agar snapshot dari ephemeral home tersimpan di persist
    fileSystems."/home/.snapshots" = {
      device = "/persist/.home-snapshots";
      options = [ "bind" ];
      depends = [ "/persist" ];
    };
  };
}
