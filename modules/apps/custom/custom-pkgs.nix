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

  flatpakCfg = {
    "com.portswigger.BurpSuitePro" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "burpsuitepro";
      nativePkgs = priv.burpsuitepro;
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "ghost-downloader";
      nativePkgs = custom.ghost-downloader-3;
    };
  };

  hmConfig = hmOpts: {
    imports = [
      inputs.custompkgs.homeModules.freqtrade-setup
    ];

    systemd.user.services.sync-flatpak-repo = {
      Unit = {
        Description = "Update private Flatpaks from Google Drive mount";
        X-SwitchMethod = "keep-old";
        After = [
          "network-online.target"
          "rclone-mount.service"
        ];
        Wants = [
          "network-online.target"
          "rclone-mount.service"
        ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "sync-flatpak-repo" ''
          set -eu
          REPO_PATH="$HOME/CloudStorage/union-raid1-decrypted/custom-flatpaks/repo"

          echo "Waiting for Google Drive FUSE mount and repository directory..."
          mounted=false
          for i in {1..60}; do
            if [ -d "$REPO_PATH" ]; then
              mounted=true
              break
            fi
            echo "Repository directory not found yet, waiting 5 seconds (attempt $i/60)..."
            sleep 5
          done

          if [ "$mounted" = false ]; then
            echo "ERROR: Google Drive mount or repository directory is not available. Skipping Flatpak update."
            exit 0
          fi

          echo "Repository directory found. Running Flatpak update..."
          ${pkgs.flatpak}/bin/flatpak update --user -y io.github.xiaoyouchr.GhostDownloader com.portswigger.BurpSuitePro
        ''}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    programs.freqtrade-setup = {
      enable = true;
      configDir = "/mnt/data_btrfs/freqtrade-dev";
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
      # custom.vimmdl
      # custom.disbox
      # custom.binance
      custom.streambert
      # Migrated to flatpak using flatpak-helper
      # custom.ghost-downloader-3
      # priv.burpsuitepro

      priv.anichin-scraper
      priv.lk21-scraper
    ];
  };
}
