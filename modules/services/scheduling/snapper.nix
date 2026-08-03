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

          # Simpan 3 snapshot per jam
          # so recently deleted files can be restored
          TIMELINE_LIMIT_HOURLY = "12";
          TIMELINE_LIMIT_DAILY = "7"; # 1 minggu harian
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "1";
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
    ];

    # Prevent system activation switches from hanging while snapper deletes snapshots
    systemd.services.snapper-timeline = {
      restartIfChanged = false;
      stopIfChanged = false;
    };
    systemd.services.snapper-cleanup = {
      restartIfChanged = false;
      stopIfChanged = false;
    };
  };
}
