{
  config,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.llama;
in
{
  options.my.system.llama = {
    enable = selfLib.mkBoolOpt false "Llama system side";

    # Deklarasikan paket kustom sebagai opsi modul
    package = lib.mkOption {
      type = lib.types.package;
      description = "Llama.cpp yang dioptimalkan untuk arsitektur Ivy Bridge";
      default = pkgsUnstable.llama-cpp.overrideAttrs (
        finalAttrs: previousAttrs: {
          cmakeFlags = (previousAttrs.cmakeFlags or [ ]) ++ [
            "-DGGML_AVX2=OFF"
            "-DGGML_FMA=OFF"
            "-DGGML_AVX=ON"
            "-DCMAKE_C_FLAGS=-march=ivybridge"
            "-DCMAKE_CXX_FLAGS=-march=ivybridge"
          ];
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Panggil opsi paket tersebut untuk diinstal ke sistem
    environment.systemPackages = [
      cfg.package
    ];
  };
}
