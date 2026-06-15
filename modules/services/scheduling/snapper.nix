{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.scheduling.snapper";

  nixosConfig = {
    # ===========================================================
    # SNAPPER — BTRFS auto-snapshots for /persist and /home
    #
    # /persist = @nixos-persist subvolume — all persistent data
    # /home    = @nixos-home subvolume (ephemeral, pre-wipe snapshot)
    #
    # Restore: snapper -c persist rollback <N>
    #   or manual copy from /persist/.snapshots/<N>/snapshot/
    #
    # NOTE: Files only in /home/ (not persisted) are wiped on boot.
    #       Add to preservation.nix for persistence.
    # ===========================================================
    services.snapper = {
      snapshotInterval = "hourly"; # Jadwal timeline snapshot
      persistentTimer = true; # Execute missed schedules on boot

      configs = {
        # Config utama: snapshot seluruh subvolume @nixos-persist
        # Mencakup: home/, var/lib/, etc/ — semua data yang dipersist
        persist = {
          SUBVOLUME = "/persist";
          ALLOW_USERS = [ config.my.user.name ];
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
          ALLOW_USERS = [ config.my.user.name ];
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

    # MUST use "Q" (not "v") — snapper requires .snapshots to be a BTRFS subvolume
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
