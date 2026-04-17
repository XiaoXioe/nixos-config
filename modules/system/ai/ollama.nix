{
  config,
  # pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.ollama;
in
{
  options.my.system.ollama = {
    enable = selfLib.mkBoolOpt false "Ollama system side";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgsUnstable.ollama;
      models = "/mnt/data_btrfs/ollama_storage/models";
    };

    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
    };
  };
}
