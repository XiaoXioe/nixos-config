{
  config,
  lib,
  pkgs,
  distroboxPruneScript,
  ...
}:

let
  cfg = config.my.virtualisation.podman;
  distroboxHelper = import ../../_lib/modules/distrobox-helper { inherit lib; };
  autoUpdateScript = distroboxHelper.mkDistroboxAutoUpdateScript {
    inherit pkgs;
    inherit (cfg) pruneOrphanContainers;
    inherit distroboxPruneScript;
  };
in
{
  systemd.user = {
    # Automatic prune service for unmanaged Distrobox containers at login/session start
    services.distrobox-prune-orphans = lib.mkIf cfg.pruneOrphanContainers {
      description = "Automatically delete unmanaged / orphan Distrobox containers";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${distroboxPruneScript}/bin/distrobox-prune";
      };
    };

    # Periodic auto-update systemd user service & timer
    services.distrobox-autoupdate = lib.mkIf cfg.autoUpdate.enable {
      description = "Auto-upgrade running Distrobox containers via debdelta / package manager";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${autoUpdateScript}";
      };
    };

    timers.distrobox-autoupdate = lib.mkIf cfg.autoUpdate.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.autoUpdate.onCalendar;
        Persistent = true;
      };
    };
  };
}
