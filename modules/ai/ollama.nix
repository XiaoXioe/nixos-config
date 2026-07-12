{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "ai.ollama";

  nixosConfig = {
    services.ollama = {
      enable = true;
      models = "/mnt/data_btrfs/ollama_storage/models";
    };

    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets."ollama-env".path ];
      };
    };
  };
}
