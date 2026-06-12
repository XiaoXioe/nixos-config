{
  config,
  pkgs,
  lib,
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

  hmConfig = {
    imports = [ inputs.custompkgs.homeManagerModules.freqtrade-setup ];
    programs.freqtrade-setup = {
      enable = true;
      configDir = "${config.home.homeDirectory}/freqtrade-dev";
      branch = "stable";
      extraPip = [ "scipy" "optuna" "plotly" "pykalman" "PyWavelets" "statsmodels" "scikit-learn" ];
      service = {
        enable = false;
        bots.bot-utama = {
          enable = true;
          strategiesDir = "/mnt/data_btrfs/freqtrade_strategies/alesta";
          strategyRun = "AlexBandSniperV65513";
          configFile = "config.json";
        };
      };
    };
    home.packages = [ custom.vimmdl custom.disbox custom.binance custom.streambert priv.anichin-scraper priv.lk21-scraper priv.burpsuitepro ];
  };
}
