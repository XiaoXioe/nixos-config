{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.theme";
  description = "Custom Themes";

  hmConfig = hmOpts: {
    home.pointerCursor = {
      name = "Vimix-white-cursors";
      package = pkgs.vimix-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
    gtk = {
      enable = true;
      gtk4.theme = hmOpts.config.gtk.theme;
      theme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-gtk-theme.override {
          colorVariants = [ "dark" ];
          tweaks = [ "normal" ];
        };
      };
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
      BROWSER = "firefox";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
