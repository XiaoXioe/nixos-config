{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.ai.ollama;
in
{
  options = selfLib.mkNestedEnable "ai.ollama";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda"; # atau false jika tidak pakai GPU
    };
  };
}
