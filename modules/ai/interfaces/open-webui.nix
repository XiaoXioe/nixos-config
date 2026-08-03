{
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "ai.interfaces.open-webui";
  description = "Open-WebUI AI interface";

  preservation = {
    persist = true;
    directories = [
      {
        directory = "/var/lib/private/open-webui";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    services.open-webui = {
      enable = true;
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
