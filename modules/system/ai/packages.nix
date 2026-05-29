{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.packages-ai;
in
{
  options.my.system.packages-ai = {
    enable = lib.mkEnableOption "Packages for ai";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      claude-code
      aider-chat
    ];
  };
}
