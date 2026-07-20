{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
  antigravity-ide = inputs.antigravity-nix.packages.${system}.google-antigravity-ide;

  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "1.18.3";

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-${platform}.tar.gz";
      inherit hash;
    };

    platform =
      if system == "x86_64-linux" then "linux-x64" else throw "opencode: unsupported platform ${system}";

    hash = "sha256-YPJ7JnnwClEbZTn5fgJEivr1jZxm4kSCheoMUXyoRYM=";

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs = with pkgs; [
      makeWrapper
      autoPatchelfHook
    ];

    buildInputs = with pkgs; [
      zlib
      openssl
      icu
      stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      tar -xzf $src -C $out/bin

      mv $out/bin/opencode $out/bin/.opencode-unwrapped
      makeWrapper $out/bin/.opencode-unwrapped $out/bin/opencode

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "OpenCode - the open source AI coding agent";
      homepage = "https://opencode.ai";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "opencode";
    };
  };
in
selfLib.mkModule {
  name = "ai.tools";
  description = "AI development tools";

  hmConfig = hmOpts: {
    home = {
      packages = [
        antigravity-cli
        antigravity-ide
        opencode
      ];

      sessionVariables = {
        NINEROUTER_URL = "http://192.168.5.207:20128";
      };
    };
  };
}
