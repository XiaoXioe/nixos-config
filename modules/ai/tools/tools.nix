{
  config,
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
  # antigravity-ide = inputs.antigravity-nix.packages.${system}.google-antigravity-ide;

  opencodeNative = (selfLib.mkNativeApp pkgs) {
    name = "opencode";
    isFOD = true;
    execPath = "opencode";
    binName = "opencode";
    isDesktop = false;
  };
in
selfLib.mkModule {
  name = "ai.tools.tools";
  description = "AI development tools";

  preservation = {
    userDirectories = [
      "xanylabeling_data"
      ".xanylabelingrc"
      ".antigravity-ide"
      ".gemini"
    ];
  };

  nixosConfig = {
    sops.secrets = {
      "huggingface-token" = {
        owner = config.my.user.name;
        mode = "0400";
        sopsFile = ./secrets.yaml;
      };
    };
    my.services.storage.btrfs-nocow-migration.nocowDirectories = [
      "/home/${config.my.user.name}/.gemini"
    ];

    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.local/share/opencode 0700 ${config.my.user.name} users - -"
    ];
  };

  hmConfig = {
    home = {
      packages = [
        antigravity-cli
        # antigravity-ide
        opencodeNative
      ];

      sessionVariables = {
        OMNIROUTE_URL = "http://192.168.5.207:20128";
        NINEROUTER_URL = "http://192.168.5.207:20128";
      };
    };
  };
}
