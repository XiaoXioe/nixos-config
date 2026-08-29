{
  pkgs,
  lib ? pkgs.lib,
  ...
}:

let
  defaultBaseLibs = import ./default-libs.nix { inherit pkgs lib; };
in
{
  pname ? name,
  name ? pname,
  version ? "latest",
  src,
  execPath ? "usr/bin/${name}",
  isDesktop ? true,
  autoPatchelf ? false,
  autoPatchelfIgnoreMissingDeps ? [ ],
  appendRunpaths ? [ ],
  extraLibs ? [ ],
  extraBuildInputs ? [ ],
  extraPostUnpack ? "",
  extraUnwrappedInstall ? "",
  meta ? { },
  ...
}:

pkgs.stdenv.mkDerivation {
  pname = "${name}-unwrapped";
  inherit version src meta;

  inherit autoPatchelfIgnoreMissingDeps appendRunpaths;

  buildInputs = lib.optionals autoPatchelf (defaultBaseLibs ++ extraLibs ++ extraBuildInputs);
  runtimeDependencies = lib.optionals autoPatchelf (defaultBaseLibs ++ extraLibs);

  nativeBuildInputs = [
    pkgs.binutils-unwrapped
    pkgs.dpkg
    pkgs.zstd
    pkgs.gnutar
    pkgs.xz
    pkgs.gzip
    pkgs.bzip2
    pkgs.unzip
    pkgs.squashfsTools
    pkgs.p7zip
  ]
  ++ lib.optional autoPatchelf pkgs.autoPatchelfHook;

  dontStrip = true;
  dontPatchELF = !autoPatchelf;

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

    ${extraPostUnpack}
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/opt/${name}"
    cp -r ./* "$out/opt/${name}/"

    if [ "${toString isDesktop}" = "1" ]; then
      if [ -d usr/share ]; then
        mkdir -p "$out/share"
        cp -r usr/share/* "$out/share/" || true
      elif [ -d share ]; then
        mkdir -p "$out/share"
        cp -r share/* "$out/share/" || true
      fi
    fi

    if [ -f "$out/opt/${name}/${execPath}" ]; then
      chmod +x "$out/opt/${name}/${execPath}"
    fi

    ${extraUnwrappedInstall}
    runHook postInstall
  '';
}
