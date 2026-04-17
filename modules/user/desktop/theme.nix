{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.themes;
in
{
  options.my.user.themes = {
    enable = selfLib.mkBoolOpt false "Custom Themes";
  };

  config = lib.mkIf cfg.enable {

    # 1. Konfigurasi Kursor Vimix White
    home.pointerCursor = {
      name = "Vimix-white-cursors";
      package = pkgs.vimix-cursors;
      size = 24; # Sesuaikan ukuran jika kurang besar/kecil
      gtk.enable = true;
      x11.enable = true; # Penting agar kursor tidak berubah saat kursor di atas aplikasi XWayland
    };

    # 2. Konfigurasi GTK (Brave, aplikasi GNOME, dll)
    gtk = {
      enable = true;
      theme = {
        # Nama folder tema yang dihasilkan oleh Nix biasanya "Colloid-Dark"
        name = "Colloid-Dark";
        # Kita gunakan fitur override Nix untuk menyuntikkan kustomisasi
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
        name = "Adwaita Mono";
        size = 10;
      };
    };

    home.sessionVariables = {
      EDITOR = "sublime -w";
      # Memaksa aplikasi Qt untuk berjalan secara native di Wayland
      QT_QPA_PLATFORM = "wayland;xcb";

      # Memaksa aplikasi Qt untuk mengikuti tema fallback jika diperlukan
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    };
  };
}
