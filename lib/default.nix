{ lib, ... }:

let
  # Cache types to avoid redundant function calls
  boolType = lib.types.bool;
  # strType = lib.types.str;
in
{
  # 1. Otomatisasi Import (Smart Scan)
  # scanPaths kini tidak lagi digunakan secara masif untuk meningkatkan performa evaluasi,
  # namun tetap dipertahankan untuk kebutuhan spesifik.
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.filterAttrs (
          name: type:
          let
            isNixFile = lib.hasSuffix ".nix" name && name != "default.nix";
            isModuleDir = type == "directory" && builtins.pathExists (path + "/${name}/default.nix");
          in
          isNixFile || isModuleDir
        ) (builtins.readDir path)
      )
    );

  # 2. Pembuat Opsi (The Game Changer)
  mkOpt =
    type: default: description:
    lib.mkOption { inherit type default description; };

  mkBoolOpt =
    default: description:
    lib.mkOption {
      type = boolType;
      default = default;
      description = description;
    };

  # 3. Shorthands (Jalan Pintas)
  enabled = {
    enable = true;
  };
  disabled = {
    enable = false;
  };

  # 4. LOGIC HELPERS
  ifElse =
    condition: yes: no:
    if condition then yes else no;

  # 5. Fungsi ajaib untuk memaku versi paket
  pinPkg =
    system: rev: pkgName:
    let
      repoPath = (builtins.getFlake "github:nixos/nixpkgs/${rev}").outPath;
      pinnedPkgs = import repoPath {
        inherit system;
        config.allowUnfree = true;
      };
    in
    pinnedPkgs.${pkgName};

  # 6. Generic Helper: Looping konfigurasi untuk SEMUA user secara global
  forAllUsers =
    users: func:
    lib.mkMerge (lib.mapAttrsToList (userName: userConfig: func userName userConfig) users);
}
