{
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.theme";
  description = "Custom Themes";

  hmConfig =
    hmOpts:
    let
      colloidTheme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-gtk-theme.override {
          colorVariants = [ "dark" ];
          tweaks = [ "normal" ];
        };
      };
    in
    {
      home.pointerCursor = {
        enable = true;
        name = "Vimix-white-cursors";
        package = pkgs.vimix-cursors;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
      gtk = {
        enable = true;
        theme = colloidTheme;
        gtk4.theme = colloidTheme;
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 10;
        };
      };
      home.sessionVariables = {
        EDITOR = "codium -w";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };
    };
}
