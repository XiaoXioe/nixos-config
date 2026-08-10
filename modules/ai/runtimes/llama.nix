{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "ai.runtimes.llama";
  options = {
    package = lib.mkOption {
      type = lib.types.package;
      description = "Llama.cpp yang dioptimalkan untuk arsitektur Ivy Bridge";
      default = pkgs.llama-cpp.overrideAttrs (
        _finalAttrs: previousAttrs: {
          version = "10299";
          src = pkgs.fetchFromGitHub {
            owner = "ggml-org";
            repo = "llama.cpp";
            rev = "refs/tags/b10299";
            sha256 = "1dkvr0y92470rzi3bnw83nszqwxipq0iwyig72pcxk60n5dh0z4g";
          };
          npmDepsHash = "sha256-FHvd2bMvBc9EXrJEzu8EN78oUVSLcOKYCc0232V+L4A=";
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
      );
    };
  };

  nixosConfig = {
    environment.systemPackages = [ config.my.ai.runtimes.llama.package ];
  };
}
