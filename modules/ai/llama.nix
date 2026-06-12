{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.ai.llama;
in
{
  options = selfLib.mkNestedOptions "ai.llama" {
    enable = lib.mkEnableOption "ai.llama";
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
    environment.systemPackages = [
      cfg.package
    ];
  };
}
