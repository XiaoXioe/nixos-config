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
        directory = "/var/lib/ollama";
        user = config.my.user.name;
        group = "users";
        mode = "0755";
      }
    ];
  };

  nixosConfig = {
    sops.secrets."ollama-env" = {
      sopsFile = ./secrets.yaml;
    };

    services.ollama = {
      enable = true;
      models = "${config.my.dataPath}/ollama_storage/models";
    };

    systemd.tmpfiles.rules = [
      "d ${config.my.dataPath}/ollama_storage 0755 ${config.my.user.name} users - -"
      "d ${config.my.dataPath}/ollama_storage/models 0755 ${config.my.user.name} users - -"
    ];

    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      restartIfChanged = false;
      serviceConfig = {
        User = config.my.user.name;
        Group = "users";
        DynamicUser = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        ProtectHome = lib.mkForce "read-only";
        UMask = lib.mkForce "0022";
        EnvironmentFile = [ config.sops.secrets."ollama-env".path ];
      };
    };
  };
}
