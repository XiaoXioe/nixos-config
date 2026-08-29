# Universal Fixed-Output Derivation (FOD) Recursive Unpacker
{
  pkgs,
  ...
}:

{
  pname ? "app",
  version ? "latest",
  url,
  hash,
  isDesktop ? true,
  extraPostUnpack ? "",
  meta ? { },
  ...
}:

pkgs.stdenvNoCC.mkDerivation {
  pname = "${pname}-unpacked";
  inherit version meta;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = hash;

  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  nativeBuildInputs = [
    pkgs.curl
    pkgs.cacert
    pkgs.gnutar
    pkgs.zstd
    pkgs.xz
    pkgs.gzip
    pkgs.bzip2
    pkgs.unzip
    pkgs.p7zip
    pkgs.dpkg
    pkgs.squashfsTools
    pkgs.binutils-unwrapped
  ];

  buildCommand = ''
    mkdir -p src_tmp "$out/opt"
    cd src_tmp

    echo "Fetching & unpacking ${pname} (${version}) from ${url}..."
    curl -sSL --retry 3 --retry-delay 2 "${url}" -o archive_file

    if [[ "${url}" == *.deb ]]; then
      mkdir -p "$out/opt/${pname}"
      ar x archive_file
      tar --no-same-permissions --no-same-owner -xf data.tar.* -C "$out/opt/${pname}"
    elif [[ "${url}" == *.pkg.tar.zst ]] || [[ "${url}" == *.tar.zst ]]; then
      mkdir -p "$out/opt/${pname}"
      tar --no-same-permissions --no-same-owner --zstd -xf archive_file -C "$out/opt/${pname}"
    elif [[ "${url}" == *.tar.xz ]] || [[ "${url}" == *.txz ]]; then
      mkdir -p "$out/opt/${pname}"
      tar --no-same-permissions --no-same-owner -xJf archive_file -C "$out/opt/${pname}"
    elif [[ "${url}" == *.tar.gz ]] || [[ "${url}" == *.tgz ]]; then
      mkdir -p "$out/opt/${pname}"
      tar --no-same-permissions --no-same-owner -xzf archive_file -C "$out/opt/${pname}"
    elif [[ "${url}" == *.tar.bz2 ]] || [[ "${url}" == *.tbz2 ]]; then
      mkdir -p "$out/opt/${pname}"
      tar --no-same-permissions --no-same-owner -xjf archive_file -C "$out/opt/${pname}"
    elif [[ "${url}" == *.tar ]]; then
      mkdir -p "$out/opt/${pname}"
      tar --no-same-permissions --no-same-owner -xf archive_file -C "$out/opt/${pname}"
    elif [[ "${url}" == *.snap ]]; then
      mkdir -p "$out/opt/${pname}"
      unsquashfs -d "$out/opt/${pname}" archive_file
    elif [[ "${url}" == *.zip ]]; then
      mkdir -p "$out/opt/${pname}"
      unzip -q archive_file -d "$out/opt/${pname}"
    elif [[ "${url}" == *.7z ]]; then
      mkdir -p "$out/opt/${pname}"
      7z x archive_file -o"$out/opt/${pname}"
    elif [[ "${url}" == *.AppImage ]]; then
      mkdir -p "$out/opt/${pname}"
      offset=$(LC_ALL=C readelf -h archive_file 2>/dev/null | awk 'NR==13{e_shoff=$5} NR==18{e_shentsize=$5} NR==19{e_shnum=$5} END{print e_shoff+e_shentsize*e_shnum}')
      if [ -n "$offset" ] && [ "$offset" -gt 0 ] && unsquashfs -q -d "$out/opt/${pname}" -o "$offset" archive_file 2>/dev/null; then
        chmod -R u+w "$out/opt/${pname}" 2>/dev/null || true
      elif unsquashfs -d "$out/opt/${pname}" archive_file 2>/dev/null; then
        chmod -R u+w "$out/opt/${pname}" 2>/dev/null || true
      elif 7z x archive_file -o"$out/opt/${pname}" 2>/dev/null; then
        true
      else
        cp -f archive_file "$out/opt/${pname}/${pname}"
        chmod 755 "$out/opt/${pname}/${pname}"
      fi
    else
      mkdir -p "$out/opt/${pname}"
      cp -f archive_file "$out/opt/${pname}/${pname}"
      chmod 755 "$out/opt/${pname}/${pname}"
    fi

    if [ "${toString isDesktop}" = "1" ]; then
      if [ -d "$out/opt/${pname}/usr/share" ]; then
        mkdir -p "$out/share"
        cp -r "$out/opt/${pname}/usr/share/"* "$out/share/" || true
      elif [ -d "$out/opt/${pname}/share" ]; then
        mkdir -p "$out/share"
        cp -r "$out/opt/${pname}/share/"* "$out/share/" || true
      fi
    fi

    cd "$out"
    ${extraPostUnpack}
  '';
}
