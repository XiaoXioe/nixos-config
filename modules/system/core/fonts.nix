{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.core.fonts;
in
{
  options.my.system.core.fonts = {
    enable = lib.mkEnableOption "system font configuration" // {
      default = true;
    };
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
