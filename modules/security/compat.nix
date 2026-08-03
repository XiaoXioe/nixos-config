{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.compat";
  description = "Binary compatibility layer (nix-ld, envfs, AppImage, ELF patching, and dynamic shared libraries)";

  nixosConfig = {
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
        libusb1
        libxml2
        libxslt
        libpng
        libjpeg
        freetype
        fontconfig
        alsa-lib
        libpulseaudio
        libdrm
        mesa
        libGL
        libxkbcommon
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
    ];
  };
}
