{
  config,
  pkgs,
  lib,
  selfLib,
  inputs,
  ...
}:
selfLib.mkModule {
  name = "ai.runtimes.llama";
  options = {
    package = lib.mkOption {
      type = lib.types.package;
      description = "Llama.cpp yang dioptimalkan untuk arsitektur Ivy Bridge";
      default = (
        inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (
          _finalAttrs: previousAttrs: {
            cmakeFlags = (previousAttrs.cmakeFlags or [ ]) ++ [
              "-DGGML_NATIVE=OFF"
              "-DLLAMA_NATIVE=OFF"
              "-DGGML_AVX2=OFF"
              "-DGGML_FMA=OFF"
              "-DGGML_AVX=ON"
              "-DGGML_F16C=ON"
              "-DCMAKE_C_FLAGS=-march=ivybridge"
              "-DCMAKE_CXX_FLAGS=-march=ivybridge"
            ];
          }
        )
      );
    };
  };

  nixosConfig = {
    environment.systemPackages = [ config.my.ai.runtimes.llama.package ];
  };
}
