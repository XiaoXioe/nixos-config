{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.fonts";
  nixosConfig = {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        adwaita-fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
        symbola
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        material-symbols
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [
            "Noto Serif"
            "Noto Color Emoji"
            "Noto Emoji"
            "Symbola"
          ];
          sansSerif = [
            "Noto Sans"
            "Noto Color Emoji"
            "Noto Emoji"
            "Symbola"
          ];
          monospace = [
            "JetBrainsMono Nerd Font"
            "Noto Color Emoji"
            "Noto Emoji"
            "Symbola"
          ];
          emoji = [
            "Noto Color Emoji"
            "Noto Emoji"
            "Symbola"
          ];
        };
      };
    };
  };
}
