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

    nix.settings = {
      # Substituters + priority
      substituters = [
        "https://cache.nixos.org?priority=0"
        "https://nix-community.cachix.org?priority=5"
        "https://cachixix.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://niri.cachix.org"
        "https://hyprland.cachix.org"
        "https://cache.garnix.io"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cachixix.cachix.org-1:gxuKepBrK+XUD1RpGPCg0pyZZrxKayVWiugCfDJebLc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];

      trusted-users = [
        "root"
        "klein-moretti"
      ];

      # ── Authenticated Cache ──────────────────────────────────────
      netrc-file = config.sops.secrets."garnix-netrc".path;
      narinfo-cache-positive-ttl = 3600;

      # Ensure substitution is active
      substitute = true; # pastikan substitusi aktif

      # ── Build behavior ───────────────────────────────────────────
      cores = 0;
      max-jobs = "auto";
      fallback = false;
      builders-use-substitutes = true;
      always-allow-substitutes = true;

      # ── Performance & stability ──────────────────────────────────
      http-connections = 50;
      download-attempts = 10;
      connect-timeout = 60;
      download-buffer-size = "256M";
      keep-outputs = true;
      keep-derivations = true;
      eval-cache = true;
      log-lines = 50; # More log lines on error

      experimental-features = [
        "nix-command"
        "flakes"
      ];

    };

    nix.gc = {
      automatic = true;
      # Runs every Monday at 10:00 AM
      dates = "Mon 10:00";
      options = "--delete-older-than 7d";
    };

    nix.extraOptions = ''
      !include ${config.sops.secrets."github-token".path}
    '';

    # Map all flake inputs to the registry
    nix.registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Sync NIX_PATH with flake registry
    nix.nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    nix.channel.enable = false;
  };
}
