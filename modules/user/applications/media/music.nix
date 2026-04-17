{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.music;
in
{
  options.my.user.music = {
    enable = selfLib.mkBoolOpt false "Music player configuration ";
  };

  config = lib.mkIf cfg.enable {
    programs.cmus = {
      enable = true;
      theme = "gruvbox";
      extraConfig = ''
        set resume=true
      '';
    };

  };
}
