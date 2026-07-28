{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "ai.ollama";

  nixosConfig = {
    sops.secrets = builtins.listToAttrs [ (selfLib.secrets.mkSecret { key = "ollama-env"; }) ];

    services.ollama = {
      enable = true;
      models = "/mnt/data_btrfs/ollama_storage/models";
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
