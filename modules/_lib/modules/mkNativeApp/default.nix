{ pkgs, lib }:

{
  mkNativeApp =
    {
      pname ? name,
      name,
      version ? "latest",
      src, # derivation / fetchurl / path lokal
      execPath ? "usr/bin/${name}", # relative path binary di dalam unpacked payload
      binName ? name, # nama binary yang diekspos di $out/bin/${binName}
      isDesktop ? true, # ekstrak desktop entries & icons ke $out/share
      desktopItem ? null, # derivation opsional dari pkgs.makeDesktopItem
      desktopName ? null, # nama file .desktop spesifik
      extraArgs ? [ ], # list string flags CLI tambahan
      extraEnv ? { }, # attrset environment variables
      extraPkgs ? [ ], # list paket dependensi biner tambahan di PATH
      passthru ? { }, # passthru attrs
      meta ? { }, # metadata derivation
    }:
    let
      envFlags = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--set ${k} \"${v}\"") extraEnv);
      argFlags = lib.concatMapStringsSep " " (arg: "--add-flags \"${arg}\"") extraArgs;

      drv = pkgs.stdenv.mkDerivation (finalAttrs: {
        inherit
          pname
          version
          src
          meta
          ;

        passthru = {
          override = _: drv;
          unwrapped = drv;
        }
        // passthru;

        nativeBuildInputs = [
          pkgs.binutils-unwrapped
          pkgs.dpkg
          pkgs.zstd
          pkgs.makeWrapper
          pkgs.gnutar
          pkgs.xz
          pkgs.gzip
          pkgs.bzip2
          pkgs.unzip
          pkgs.squashfsTools
          pkgs.p7zip
        ];
        buildInputs = [ ];
        dontStrip = true;
        dontPatchELF = true;

        unpackPhase = ''
          runHook preUnpack
          mkdir -p build_src && cd build_src

          if [[ "$src" == *.deb ]]; then
            ar x "$src"
            tar --no-same-permissions --no-same-owner -xf data.tar.*
            rm -f control.tar.* data.tar.* debian-binary
          elif [[ "$src" == *.pkg.tar.zst ]] || [[ "$src" == *.tar.zst ]]; then
            tar --no-same-permissions --no-same-owner --zstd -xf "$src"
          elif [[ "$src" == *.tar.xz ]] || [[ "$src" == *.txz ]]; then
            tar --no-same-permissions --no-same-owner -xJf "$src"
          elif [[ "$src" == *.tar.gz ]] || [[ "$src" == *.tgz ]]; then
            tar --no-same-permissions --no-same-owner -xzf "$src"
          elif [[ "$src" == *.tar.bz2 ]] || [[ "$src" == *.tbz2 ]]; then
            tar --no-same-permissions --no-same-owner -xjf "$src"
          elif [[ "$src" == *.tar ]]; then
            tar --no-same-permissions --no-same-owner -xf "$src"
          elif [[ "$src" == *.snap ]]; then
            unsquashfs -d . "$src"
          elif [[ "$src" == *.zip ]]; then
            unzip -q "$src"
          elif [[ "$src" == *.7z ]]; then
            7z x "$src"
          elif [[ "$src" == *.AppImage ]]; then
            offset=$(LC_ALL=C readelf -h "$src" 2>/dev/null | awk 'NR==13{e_shoff=$5} NR==18{e_shentsize=$5} NR==19{e_shnum=$5} END{print e_shoff+e_shentsize*e_shnum}')
            if [ -n "$offset" ] && [ "$offset" -gt 0 ] && unsquashfs -q -d . -o "$offset" "$src" 2>/dev/null; then
              chmod go-w . 2>/dev/null || true
            elif unsquashfs -d . "$src" 2>/dev/null; then
              chmod go-w . 2>/dev/null || true
            elif 7z x "$src" 2>/dev/null; then
              true
            else
              mkdir -p "$(dirname "${execPath}")"
              cp -f "$src" "${execPath}"
              chmod 755 "${execPath}"
            fi
          else
            if [ -f "$src" ]; then
              mkdir -p "$(dirname "${execPath}")"
              cp -f "$src" "${execPath}"
              chmod 755 "${execPath}"
            else
              cp -r "$src"/* .
            fi
          fi
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/opt/${name}" "$out/bin"

          cp -r ./* "$out/opt/${name}/"

          if [ "${toString isDesktop}" = "1" ]; then
            if [ -d usr/share ]; then
              mkdir -p "$out/share"
              cp -r usr/share/* "$out/share/" || true
            elif [ -d share ]; then
              mkdir -p "$out/share"
              cp -r share/* "$out/share/" || true
            fi

            if [ -d "$out/share/applications" ]; then
              for f in "$out/share/applications/"*.desktop; do
                [ -f "$f" ] || continue
                substituteInPlace "$f" \
                  --replace-quiet "/usr/bin/${name}" "$out/bin/${binName}" \
                  --replace-quiet "/usr/bin/${binName}" "$out/bin/${binName}" \
                  --replace-quiet "/opt/${name}/${name}" "$out/bin/${binName}" \
                  --replace-quiet "Exec=${name}" "Exec=$out/bin/${binName}" \
                  --replace-quiet "Exec=${binName}" "Exec=$out/bin/${binName}" || true
              done
            fi
          fi

          ${lib.optionalString (desktopItem != null) ''
            mkdir -p "$out/share/applications"
            cp ${desktopItem}/share/applications/* "$out/share/applications/" || true
          ''}

          if [ -f "$out/opt/${name}/${execPath}" ]; then
            chmod +x "$out/opt/${name}/${execPath}"
          fi

          makeWrapper "$out/opt/${name}/${execPath}" "$out/bin/${binName}" \
            --prefix LD_LIBRARY_PATH : "/run/current-system/sw/share/nix-ld/lib" \
            --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$out/share" \
            --set-default GSETTINGS_SCHEMA_DIR "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas" \
            --set-default XKB_CONFIG_ROOT "${pkgs.xkeyboard_config}/share/X11/xkb" \
            --set-default QT_XKB_CONFIG_ROOT "${pkgs.xkeyboard_config}/share/X11/xkb" \
            --prefix PATH : "${
              lib.makeBinPath (
                [
                  pkgs.coreutils
                  pkgs.util-linux
                  pkgs.xdg-utils
                  pkgs.bash
                ]
                ++ extraPkgs
              )
            }" \
            ${envFlags} \
            ${argFlags}

          runHook postInstall
        '';
      });
    in
    drv;
}
