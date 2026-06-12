{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.boot-speedup;
  inherit (lib) mkIf;
in
{
  options = selfLib.mkNestedEnable "services.boot-speedup.drkonqi";

  config = mkIf (cfg.enable && cfg.drkonqi.enable) {
    systemd.services."drkonqi-coredump-processor@".enable = false;
    systemd.user.sockets."drkonqi-coredump-launcher".enable = false;
    systemd.user.services."drkonqi-coredump-launcher".enable = false;
  };
}
