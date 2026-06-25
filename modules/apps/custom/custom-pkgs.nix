{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  custom = inputs.custompkgs.packages.${system};
  priv = inputs.custompkgs-priv.packages.${system};
in
selfLib.mkModule {
  name = "apps.custompkgs";
  description = "Custom packages";

  hmConfig = { config, ... }: {
    imports = [ inputs.custompkgs.homeModules.freqtrade-setup ];
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
        enable = true;
        startupDelay = "3m";
        bots = {
          bot-xstar = {
            enable = true;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/coba";
            strategyRun = "xstar";
            configFile = "config.json";
            memoryLimit = "2G";
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-xstar-v1 = {
            enable = true;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/coba";
            strategyRun = "xstar_V1";
            configFile = "config_v1.json";
            memoryLimit = "2G";
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-coba-freqai = {
            enable = true;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/coba";
            strategyRun = "coba_freqai";
            configFile = "config-freqai.json";
            memoryLimit = "2G";
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-chronos = {
            enable = true;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/timesfm";
            strategyRun = "Chronos2_AdvancedScalper";
            configFile = "config.json";
            memoryLimit = "2G";
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-smc = {
            enable = false;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/smc";
            strategyRun = "SMCStrategy";
            configFile = "config.json";
            memoryLimit = "2G";
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-tfm = {
            enable = false;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/timesfm";
            strategyRun = "TimesFMScalpingFutures5m";
            configFile = "config.json";
            memoryLimit = "2G";
            extra = [
              "uvicorn timesfm_api:app --host 127.0.0.1 --port 8000"
            ];
            logToFile = true;
            logMaxSize = "10M";
          };
          bot-tfmbb = {
            memoryLimit = "2G";
            enable = false;
            strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/timesfm";
            strategyRun = "TimesFMBBScalpingFutures30m";
            configFile = "config-30m.json";
            logToFile = true;
            logMaxSize = "10M";
          };
        };
      };
    };
    home.packages = [
      custom.vimmdl
      # custom.disbox
      # custom.binance
      custom.streambert

      priv.anichin-scraper
      priv.lk21-scraper
      priv.burpsuitepro
    ];
  };
}
