{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ai.llama;
in
{
  options.my.system.ai.llama = {
    enable = lib.mkEnableOption "Llama system side";

    # Deklarasikan paket kustom sebagai opsi modul
    package = lib.mkOption {
      type = lib.types.package;
      description = "Llama.cpp yang dioptimalkan untuk arsitektur Ivy Bridge";
      default = pkgs.llama-cpp.overrideAttrs (
        _finalAttrs: previousAttrs: {
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
    # Install the package to the system
    environment.systemPackages = [
      cfg.package
    ];
  };
}
