{
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.compat";
  description = "Binary compatibility layer (nix-ld, envfs, AppImage, ELF patching, and dynamic shared libraries)";

  nixosConfig =
    { config, pkgs, ... }:
    let
      activeSources = selfLib.activeAppSources { inherit pkgs config; };
    in
    {
      # Automatic /bin/bash & /usr/bin/env compatibility symlinks for scripts
      services.envfs.enable = true;

      # Dynamic linker loader for unpatched 64-bit ELF binaries
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          fuse3
          fuse
          icu
          nss
          nspr
          openssl
          curl
          expat
          glib
          gtk3
          gtk4
          gdk-pixbuf
          pango
          cairo
          atk
          at-spi2-core
          dbus
          libdbusmenu-gtk3
          libsecret
          cups
          libnotify
          libayatana-appindicator
          libayatana-indicator
          ayatana-ido
          libepoxy
          libusb1
          libxml2
          libxslt
          libpng
          libjpeg
          freetype
          fontconfig
          alsa-lib
          libpulseaudio
          pipewire
          libjack2
          portaudio
          libsamplerate
          SDL
          SDL2
          libdrm
          mesa
          libgbm
          libGL
          libvdpau
          libva
          libdecor
          libxcb
          libxkbcommon
          libxkbfile
          vulkan-loader
          flac
          harfbuzz
          dav1d
          double-conversion
          lcms2
          minizip
          openh264
          openjpeg
          libopus
          qt6.qtbase
          qt6.qtsvg
          qt6.qtwayland
          bluez
          cubeb
          enet
          libevdev
          fmt_9
          hidapi
          lzo
          mbedtls
          mgba
          miniupnpc
          pugixml
          sfml
          stb
          xxhash
          ffmpeg
          wayland
          libX11
          libXcursor
          libXi
          libXrandr
          libXrender
          libXcomposite
          libXdamage
          libXext
          libXfixes
          libXtst
          libXScrnSaver
          libxshmfence
          libXinerama
          systemd
        ];
      };

      # System compatibility tools for running & inspecting unpatched binaries
      environment.systemPackages = with pkgs; [
        appimage-run
        patchelf
        binutils
        file
        steam-run
        xkeyboard_config
        activeSources
      ];

      # Kunci seluruh file sumber (.deb, .tar.xz, .AppImage) aplikasi aktif sebagai GC Root sistem
      # agar kebal terhadap garbage collection (nh clean / nix-collect-garbage)
      system.extraDependencies = [
        activeSources
      ];

      environment.sessionVariables = {
        XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/share/X11/xkb";
        QT_XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/share/X11/xkb";
      };
    };
}
