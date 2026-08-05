{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.hyprland.nandoroid";
  description = "NAnDoroid shell for Hyprland";

  nixosConfig = { };

  hmConfig = hmOpts: {
    # Link Quickshell and Matugen configuration
    xdg.configFile = selfLib.mkHmSymlinks hmOpts.config {
      "quickshell/nandoroid" =
        "${config.my.user.flakePath}/modules/desktop/hyprland/nandoroid/dotfiles/quickshell";
      "matugen" = "${config.my.user.flakePath}/modules/desktop/hyprland/nandoroid/dotfiles/matugen";
    };

    systemd.user.tmpfiles.rules = [
      "d %h/.config/hypr/hyprland 0755 - - -"
      "d %h/.config/hypr/hyprlock 0755 - - -"
      "f %h/.config/hypr/hyprland/colors.conf 0644 - - - # placeholder for matugen colors"
      "f %h/.config/hypr/hyprlock/colors.conf 0644 - - - # placeholder for matugen colors"
    ];

    home.packages = with pkgs; [
      (lib.lowPrio (symlinkJoin {
        name = "quickshell-wrapped";
        paths = [ quickshell ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/quickshell \
            --prefix QML2_IMPORT_PATH : "${kdePackages.qt5compat}/lib/qt-6/qml" \
            --prefix QML2_IMPORT_PATH : "${kdePackages.qtdeclarative}/lib/qt-6/qml" \
            --prefix QML2_IMPORT_PATH : "${kdePackages.qtsvg}/lib/qt-6/qml" \
            --prefix QML2_IMPORT_PATH : "${kdePackages.qtwayland}/lib/qt-6/qml" \
            --set QSG_RENDER_LOOP threaded \
            --set QSG_RHI_BACKEND opengl \
            --set QT_WAYLAND_DISABLE_WINDOWDECORATION 1 \
            --set QT_SCALE_FACTOR_ROUNDING_POLICY RoundPreferFloor
        '';
      }))
      matugen
      dgop
      jq
      brightnessctl
      playerctl
      wf-recorder
      imagemagick
      ffmpeg
      songrec
      cava
      hyprpicker
      hyprlock
      hyprsunset
      cliphist
      zenity
      translate-shell
    ];
  };
}
