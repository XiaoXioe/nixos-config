{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.open-webui;
in
{
  options.my.system.open-webui = {
    enable = selfLib.mkBoolOpt false "Open-WebUI settings";
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      package = pkgs.open-webui;
      port = 8081;
      host = "127.0.0.1";
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      };
    };

    systemd.services.open-webui = {
      wantedBy = lib.mkForce [ ];
      bindsTo = [ "ollama.service" ];
      after = [ "ollama.service" ];
    };

    systemd.services.ollama.wants = [ "open-webui.service" ];
  };
}
