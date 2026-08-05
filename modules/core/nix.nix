{
  config,
  lib,
  inputs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.nix";

  preservation = {
    persist = true;
    directories = [ "/var/lib/nixos" ];
  };

  hmConfig = hmOpts: {
    home.file = selfLib.mkHmSymlinks hmOpts.config {
      ".cache/nix/gitv3" = "/persist/home/${hmOpts.osConfig.my.user.name}/.cache/nix/gitv3";
      ".cache/nix/tarball-cache-v2" =
        "/persist/home/${hmOpts.osConfig.my.user.name}/.cache/nix/tarball-cache-v2";
    };
  };

  nixosConfig = {
    nix = {
      settings = {
        # Substituters + priority
        substituters = [
          "https://cache.nixos.org?priority=0"
          "https://nixos-cache-proxy.cofob.dev?priority=10"
          "https://nix-community.cachix.org"
          "https://cachixix.cachix.org"
          "https://nix-mcp.cachix.org"
          "https://niri.cachix.org"
          "https://hyprland.cachix.org"
          "https://attic.xuyh0120.win/lantian"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cachixix.cachix.org-1:gxuKepBrK+XUD1RpGPCg0pyZZrxKayVWiugCfDJebLc="
          "nix-mcp.cachix.org-1:fX4XSh0PcNT7FJx0+41n9XxifTVsrFz7vTwMgdLsgig="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        ];

        trusted-users = [
          "root"
          config.my.user.name
        ];

        # Ensure substitution is active
        substitute = true;

        # ── Build behavior ───────────────────────────────────────────
        cores = 0;
        max-jobs = "auto";
        fallback = false;
        builders-use-substitutes = true;
        always-allow-substitutes = true;

        # ── Performance & stability ──────────────────────────────────
        max-substitution-jobs = 4;
        http-connections = 16;
        download-attempts = 3;
        connect-timeout = 10;
        stalled-download-timeout = 300;
        keep-outputs = true;
        keep-derivations = true;
        eval-cache = true;
        log-lines = 50;
        narinfo-cache-negative-ttl = 60;

        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
      };

      gc = {
        automatic = false;
      };

      extraOptions = ''
        !include ${config.sops.secrets."github-nix".path}
      '';

      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value}") inputs;
      channel.enable = false;
    };

    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.config/cachix 0700 ${config.my.user.name} users - -"
    ];
    sops = {
      templates."cachix.dhall" = {
        path = "/home/${config.my.user.name}/.config/cachix/cachix.dhall";
        owner = config.my.user.name;
        mode = "0600";
        content = ''
          { authToken = "${config.sops.placeholder.cachix-token}" }
        '';
      };
      secrets = {
        "github-nix" = {
          sopsFile = ./secrets.yaml;
          owner = config.my.user.name;
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };
        "cachix-token" = {
          sopsFile = ./secrets.yaml;
          owner = config.my.user.name;
          group = "users";
        };
      };
    };
  };
}
