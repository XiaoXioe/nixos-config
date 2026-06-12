{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.bootSpeedup;
  inherit (lib) mkIf;
in
{
  options.my.system.services.bootSpeedup.drkonqi = {
    enable = lib.mkEnableOption "disable drkonqi coredump processor and launcher" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.drkonqi.enable) {
    systemd.services."drkonqi-coredump-processor@".enable = false;
    systemd.user.sockets."drkonqi-coredump-launcher".enable = false;
    systemd.user.services."drkonqi-coredump-launcher".enable = false;
  };
}
