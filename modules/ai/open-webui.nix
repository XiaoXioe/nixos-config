{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.ai.open-webui;
in
{
  options = selfLib.mkNestedEnable "ai.open-webui";

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = 8080;
    };
  };
}
