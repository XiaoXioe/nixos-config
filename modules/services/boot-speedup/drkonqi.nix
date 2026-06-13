{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.services.boot-speedup.enable {
    systemd.services."drkonqi-coredump-processor@".enable = false;
    systemd.user.sockets."drkonqi-coredump-launcher".enable = false;
    systemd.user.services."drkonqi-coredump-launcher".enable = false;
  };
}
