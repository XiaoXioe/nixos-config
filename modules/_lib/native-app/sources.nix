# Native App source downloaders, unpacking shorthands, and linkFarm generators
{
  lib,
  pkgs,
  fetchUnpacked,
  appVersionsData,
}:

rec {
  # Unduh file installer upstream mentah untuk aplikasi terdaftar
  fetchApp = name: pkgs.fetchurl appVersionsData.${name};

  # Unduh & unpack arsip aplikasi terdaftar menggunakan fixed-output derivation
  fetchUnpackedApp =
    name:
    let
      info = appVersionsData.${name};
      hash = info.unpackedHash or info.hash;
    in
    fetchUnpacked (
      info
      // {
        pname = name;
        inherit hash;
      }
    );

  # Bangun linkFarm berisi seluruh paket installer upstream di apps-versions.nix
  allAppSources = pkgs.linkFarm "native-app-sources" (
    lib.mapAttrsToList (name: info: {
      name = "${name}-${info.version}";
      path = pkgs.fetchurl {
        inherit (info) url hash;
      };
    }) appVersionsData
  );

  # Bangun linkFarm hanya untuk paket aplikasi yang benar-benar aktif di konfigurasi host
  activeAppSources =
    config:
    let
      # Alias jika nama modul sedikit berbeda dengan nama key di apps-versions.nix
      aliases = {
        zed = "zeditor";
        betterbird = "thunderbird";
        ppsspp = "emulators";
        pcsx2 = "emulators";
        retroarch = "emulators";
        retroarch-cores = "emulators";
        tdl = "downloader";
      };

      # Cek apakah modul dengan nama tertentu aktif di config.my tree.
      # Melakukan traversal hingga kedalaman 3 untuk mendukung nested module paths.
      isModuleEnabled =
        name:
        let
          targetKey = aliases.${name} or name;

          checkAtDepth =
            depth: set:
            if depth > 3 || !builtins.isAttrs set then
              false
            else if set ? ${targetKey} && builtins.isAttrs set.${targetKey} && set.${targetKey} ? enable then
              set.${targetKey}.enable == true
            else
              lib.any (child: checkAtDepth (depth + 1) child) (
                lib.filter (v: builtins.isAttrs v && !(v ? _type)) (builtins.attrValues set)
              );
        in
        checkAtDepth 0 (config.my.apps or { }) || checkAtDepth 0 (config.my.security or { });

      activeEntries = lib.filterAttrs (name: _: isModuleEnabled name) appVersionsData;
    in
    pkgs.linkFarm "native-app-sources" (
      lib.mapAttrsToList (name: info: {
        name = "${name}-${info.version}";
        path = pkgs.fetchurl {
          inherit (info) url hash;
        };
      }) activeEntries
    );
}
