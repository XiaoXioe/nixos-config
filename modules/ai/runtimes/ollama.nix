{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "ai.runtimes.ollama";
  description = "Ollama LLM runtime service";

  preservation = {
    persist = true;
    directories = [
      {
        directory = "/var/lib/private/ollama";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    sops.secrets."ollama-env" = {
      sopsFile = ./secrets.yaml;
    };

    services.ollama = {
      enable = true;
      models = "${config.my.dataBtrfsPath}/ollama_storage/models";
    };

    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      restartIfChanged = false;
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets."ollama-env".path ];
      };
    };
  };
}
