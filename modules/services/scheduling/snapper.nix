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

          # Restore point jangka pendek yang hemat ruang disk (Balanced Lean)
          TIMELINE_LIMIT_HOURLY = "5"; # 5 jam terakhir untuk undo cepat
          TIMELINE_LIMIT_DAILY = "4"; # 4 hari terakhir untuk rollback sesi kemarin
          TIMELINE_LIMIT_WEEKLY = "1"; # 1 checkpoint minggu ini
          TIMELINE_LIMIT_MONTHLY = "0"; # Jangka panjang didelegasikan ke Restic
          TIMELINE_LIMIT_YEARLY = "0";

          # Guardrails penghematan ruang disk BTRFS
          SPACE_LIMIT = "0.3"; # Maksimal snapshot menggunakan 30% kapasitas partisi
          FREE_LIMIT = "0.2"; # Picu cleanup agresif jika sisa kapasitas disk < 20%
        };
      };
    };

    # More frequent cleanup schedule to prevent accumulation

    # MUST use "Q" (not "v") — snapper requires .snapshots to be a BTRFS subvolume

    # Prevent system activation switches from hanging while snapper deletes snapshots

    systemd = {
      timers."snapper-cleanup" = {
        timerConfig = {
          OnCalendar = lib.mkForce "*-*-* *:30:00";
        };
      };

      tmpfiles.rules = [
        "Q /persist/.snapshots 0750 root root - -"
      ];

      services = {
        snapper-timeline = {
          onFailure = [ "status-alert@snapper-timeline.service" ];
          restartIfChanged = false;
          stopIfChanged = false;
        };
        snapper-cleanup = {
          onFailure = [ "status-alert@snapper-cleanup.service" ];
          restartIfChanged = false;
          stopIfChanged = false;
        };
      };
    };
  };
}
