{
  config,
  lib,
  inputs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.nix";

  hmConfig = hmOpts: {
    home.file.".cache/nix/gitv3".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "/persist/home/${hmOpts.osConfig.my.user.name}/.cache/nix/gitv3";
    home.file.".cache/nix/tarball-cache-v2".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "/persist/home/${hmOpts.osConfig.my.user.name}/.cache/nix/tarball-cache-v2";
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
          "https://niri.cachix.org"
          "https://hyprland.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cachixix.cachix.org-1:gxuKepBrK+XUD1RpGPCg0pyZZrxKayVWiugCfDJebLc="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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
        max-substitution-jobs = 3;
        http-connections = 50;
        download-attempts = 5;
        connect-timeout = 60;
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

    # Direct nix-daemon network traffic through wireproxy-warp SOCKS5 at 127.0.0.1:40000
    systemd.services.nix-daemon.environment = {
      http_proxy = "socks5://127.0.0.1:40000";
      https_proxy = "socks5://127.0.0.1:40000";
      all_proxy = "socks5://127.0.0.1:40000";
      NO_PROXY = "localhost,127.0.0.1,::1";
      no_proxy = "localhost,127.0.0.1,::1";
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
          owner = config.my.user.name;
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };
        "cachix-token" = {
          owner = config.my.user.name;
          group = "users";
        };
      };
    };
  };
}
