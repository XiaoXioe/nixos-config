{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.system.nix-settings;
in
{
  options.my.system.nix-settings = {
    enable = lib.mkEnableOption "Nix settings";
  };

  config = lib.mkIf cfg.enable {

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
          "klein-moretti"
        ];

        # Ensure substitution is active
        substitute = true; # pastikan substitusi aktif

        # ── Build behavior ───────────────────────────────────────────
        cores = 0;
        max-jobs = "auto";
        fallback = false;
        builders-use-substitutes = true;
        always-allow-substitutes = true;

        # ── Performance & stability ──────────────────────────────────
        http-connections = 128;
        download-attempts = 128;
        connect-timeout = 60;
        download-buffer-size = "256M";
        keep-outputs = true;
        keep-derivations = true;
        eval-cache = true;
        log-lines = 50; # More log lines on error

        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
      };

      gc = {
        automatic = true;
        # Runs every Monday at 10:00 AM
        dates = "Mon 10:00";
        options = "--delete-older-than 7d";
      };
      extraOptions = ''
        !include ${config.sops.secrets."github-token".path}
      '';

      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
      channel.enable = false;
    };
  };
}
