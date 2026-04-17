{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.snapper;
in
{
  options.my.services.snapper = {
    enable = selfLib.mkBoolOpt false "Snapper backup home data";
  };

  config = lib.mkIf cfg.enable {
    services.snapper.configs = {
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = lib.mapAttrsToList (name: _: name) config.my.users;
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        TIMELINE_LIMIT_HOURLY = "3";
        TIMELINE_LIMIT_DAILY = "5";
        TIMELINE_LIMIT_WEEKLY = "1";
        TIMELINE_LIMIT_MONTHLY = "0";
        TIMELINE_LIMIT_YEARLY = "0";
      };
    };

    # Override timer bawaan snapper-cleanup agar berjalan setiap jam di menit 30
    systemd.timers."snapper-cleanup" = {
      timerConfig = {
        OnCalendar = lib.mkForce "*-*-* *:30:00";
      };
    };
  };
}
