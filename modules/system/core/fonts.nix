{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.fonts;
in
{
  options.my.system.fonts = {
    enable = selfLib.mkBoolOpt false "system font configuration";
  };

  config = lib.mkIf cfg.enable {
    fonts.fontDir.enable = true;
    fonts.packages = with pkgs; [
      adwaita-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
  };
}
