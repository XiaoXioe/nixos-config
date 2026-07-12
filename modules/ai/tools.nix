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
      ];
    };
  };
}
