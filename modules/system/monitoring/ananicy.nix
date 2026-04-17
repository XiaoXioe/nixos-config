{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.ananicy;
in
{
  options.my.services.ananicy = {
    enable = selfLib.mkBoolOpt false "ananicy-cpp service with cachyos rules";
  };

  config = lib.mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;

      settings = {
        check_freq = 3;
        apply_cgroup = lib.mkForce false;
        cgroup_load = lib.mkForce false;
        cgroup_realtime_workaround = lib.mkForce false;

        apply_nice = true;
        apply_sched = true;
        apply_ionice = true;
        apply_ioclass = true;
        apply_oom_score_adj = true;
        check_disks_schedulers = true;

        type_load = true;
        rule_load = true;

        #   log_level = "warn";
      };
    };
  };
}
