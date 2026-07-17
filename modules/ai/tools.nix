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
  codex-cli = inputs.codex-cli.packages.${system}.default;
  claude-code = inputs.claude-code.packages.${system}.default;

  opencode = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    version = "1.18.3";

    src =
      let
        platformMap = {
          "x86_64-linux" = "linux-x64";
          "aarch64-linux" = "linux-arm64";
        };
        platform = platformMap.${system} or (throw "Unsupported platform: ${system}");
        hashes = {
          "linux-x64" = "60f27b2679f00a511b6539f97e02448afaf58d9c66e2448285ea0c517ca84583";
          "linux-arm64" = "da0a631174eba380b2a1d51f9d364fa3812da433e72743c72471d4b5da59c69d";
        };
      in
      pkgs.fetchurl {
        url = "https://github.com/anomalyco/opencode/releases/download/v1.18.3/opencode-${platform}.tar.gz";
        sha256 = hashes.${platform};
      };

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs = [
      pkgs.makeBinaryWrapper
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.zlib
      pkgs.openssl
      pkgs.icu
      pkgs.stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      tar -xzf $src -C $out/bin

      mv $out/bin/opencode $out/bin/.opencode-unwrapped
      makeBinaryWrapper $out/bin/.opencode-unwrapped $out/bin/opencode

      runHook postInstall
    '';

    meta = {
      description = "OpenCode - the open source AI coding agent";
      homepage = "https://opencode.ai";
      license = pkgs.lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
        claude-code
        codex-cli
        opencode
      ];
    };
  };
}
