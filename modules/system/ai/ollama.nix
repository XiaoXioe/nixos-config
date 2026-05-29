{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ollama;
in
{
  options.my.system.ollama = {
    enable = lib.mkEnableOption "Ollama system side";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama;
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
