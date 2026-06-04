{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ai.packages;
in
{
  options.my.system.ai.packages = {
    enable = lib.mkEnableOption "Packages for ai";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      claude-code
      aider-chat
    ];
  };
}
