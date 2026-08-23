{ pkgs, lib }:

{
  pname ? name,
  name ? pname,
  version ? "latest",
  unwrapped,
  execPath ? "usr/bin/${name}",
  binName ? name,
  isDesktop ? true,
  desktopItem ? null,
  extraArgs ? [ ],
  extraEnv ? { },
  extraPkgs ? [ ],
  extraLibs ? [ ],
  extraWrapperArgs ? [ ],
  extraPostInstall ? "",
  passthru ? { },
  meta ? { },
  ...
}:
let
  envFlags = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--set ${k} \"${v}\"") extraEnv);
  argFlags = lib.concatMapStringsSep " " (arg: "--add-flags \"${arg}\"") extraArgs;
  wrapperFlags = lib.concatStringsSep " " extraWrapperArgs;

  drvWrapped = pkgs.stdenv.mkDerivation (_finalAttrs: {
    inherit
      pname
      version
      ;

    meta = {
      mainProgram = binName;
    }
    // meta;

    passthru = {
      inherit unwrapped;
      override = _: drvWrapped;
    }
    // passthru;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"

      if [ "${toString isDesktop}" = "1" ]; then
        if [ -d "${unwrapped}/share" ]; then
          mkdir -p "$out/share"
          cp -r "${unwrapped}/share/"* "$out/share/" 2>/dev/null || true
        fi

        if [ -d "$out/share/applications" ]; then
          chmod -R u+w "$out/share/applications" 2>/dev/null || true
          for f in "$out/share/applications/"*.desktop; do
            [ -f "$f" ] || continue
            substituteInPlace "$f" \
              --replace-quiet "/usr/share/${name}/${name}" "$out/bin/${binName}" \
              --replace-quiet "/usr/share/${name}/${binName}" "$out/bin/${binName}" \
              --replace-quiet "/usr/bin/${name}" "$out/bin/${binName}" \
              --replace-quiet "/usr/bin/${binName}" "$out/bin/${binName}" \
              --replace-quiet "/opt/${name}/${name}" "$out/bin/${binName}" \
              --replace-quiet "/${execPath}" "$out/bin/${binName}" \
              --replace-quiet "Exec=${name}" "Exec=$out/bin/${binName}" \
              --replace-quiet "Exec=${binName}" "Exec=$out/bin/${binName}" || true
          done
        fi
      fi

      ${lib.optionalString (desktopItem != null) ''
        mkdir -p "$out/share/applications"
        cp ${desktopItem}/share/applications/* "$out/share/applications/" || true
      ''}

      makeWrapper "${unwrapped}/opt/${name}/${execPath}" "$out/bin/${binName}" \
        --prefix LD_LIBRARY_PATH : "${
          lib.optionalString (extraLibs != [ ]) "${lib.makeLibraryPath extraLibs}:"
        }/run/current-system/sw/share/nix-ld/lib" \
        --prefix NIX_LD_LIBRARY_PATH : "${
          lib.optionalString (extraLibs != [ ]) "${lib.makeLibraryPath extraLibs}:"
        }/run/current-system/sw/share/nix-ld/lib" \
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
        ${wrapperFlags} \
        ${envFlags} \
        ${argFlags}

      ${extraPostInstall}

      runHook postInstall
    '';
  });
in
drvWrapped
