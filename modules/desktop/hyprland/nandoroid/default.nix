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
    # Link Quickshell configuration for nandoroid
    xdg.configFile."quickshell/nandoroid".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "${config.my.user.flakePath}/dotfiles/quickshell/nandoroid";

    # Link Matugen configuration
    xdg.configFile."matugen".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "${config.my.user.flakePath}/dotfiles/matugen";

    home.activation.createNandoroidDirs = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.coreutils}/bin/mkdir -p $HOME/.config/hypr/hyprland $HOME/.config/hypr/hyprlock
      if [ ! -f $HOME/.config/hypr/hyprland/colors.conf ]; then
        ${pkgs.coreutils}/bin/echo "# placeholder for matugen colors" > $HOME/.config/hypr/hyprland/colors.conf
      fi
      if [ ! -f $HOME/.config/hypr/hyprlock/colors.conf ]; then
        ${pkgs.coreutils}/bin/echo "# placeholder for matugen colors" > $HOME/.config/hypr/hyprlock/colors.conf
      fi
    '';

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
