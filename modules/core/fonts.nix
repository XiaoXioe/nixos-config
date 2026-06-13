{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.fonts";
  nixosConfig = {
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
