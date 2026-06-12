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
  options.my.system.services.bootSpeedup.networking = {
    enable = lib.mkEnableOption "disable networking services (NM-wait-online, ModemManager)" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.networking.enable) {
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;
  };
}
