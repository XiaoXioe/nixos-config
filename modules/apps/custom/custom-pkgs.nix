{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.user.apps.custompkgs;

  system = pkgs.stdenv.hostPlatform.system;
  custom = inputs.custompkgs.packages.${system};
  priv = inputs.custompkgs-priv.packages.${system};
in
{
  imports = [
    inputs.custompkgs.homeModules.freqtrade-setup
  ];
  options.my.user.apps.custompkgs = {
    enable = lib.mkEnableOption "Custom packages";
  };

  config = lib.mkIf cfg.enable {
    programs.freqtrade-setup = {
      enable = true;
      configDir = "${config.home.homeDirectory}/freqtrade-dev";
      branch = "stable";
      extraPip = [
        "scipy"
        "optuna"
        "plotly"
        "pykalman"
        "PyWavelets"
        "statsmodels"
        "scikit-learn"
      ];
      service = {
        enable = false;
        bots = {
          bot-utama = {
            enable = true;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/alesta";
            strategyRun = "AlexBandSniperV65513";
            configFile = "config.json";
          };
        };
      };
    };
    home.packages = [
      # --- Custompkgs Publik ---
      custom.vimmdl
      custom.disbox
      custom.binance
      custom.streambert

      # --- Paket dari Private Repo ---
      priv.anichin-scraper
      priv.lk21-scraper
      priv.burpsuitepro
      # priv.titan-agent
    ];
  };
}
