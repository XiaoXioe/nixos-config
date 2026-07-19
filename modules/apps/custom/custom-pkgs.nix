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
      skipInstall = true;
      binName = "burpsuitepro";
      nativePkgs = priv.burpsuitepro;
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = true;
      skipInstall = true;
      binName = "ghost-downloader";
      nativePkgs = custom.ghost-downloader-3;
    };
  };

  hmConfig = hmOpts: {
    imports = [
      inputs.custompkgs.homeModules.freqtrade-setup
    ];

    systemd.user.services.install-custom-flatpaks = {
      Unit = {
        Description = "Download and install custom private flatpaks";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "install-custom-flatpaks" ''
          set -eu
          mkdir -p $HOME/.cache/custom-flatpaks
          cd $HOME/.cache/custom-flatpaks

          echo "Downloading flatpak bundles from private release..."

          MAX_RETRIES=10
          apps=("com.portswigger.BurpSuitePro" "io.github.xiaoyouchr.GhostDownloader")

          mkdir -p "$HOME/.local/state/custom-flatpaks"

          # Wait for network connectivity and gh to be able to authenticate/query
          echo "Verifying network and GitHub authentication..."
          network_ready=false
          for i in {1..15}; do
            if ${pkgs.gh}/bin/gh release view v1.0.0 -R XiaoXioe/flatpak-packages >/dev/null 2>&1; then
              network_ready=true
              break
            fi
            echo "Network or GitHub CLI not ready yet, retrying in 3 seconds (attempt $i/15)..."
            sleep 3
          done

          if [ "$network_ready" = false ]; then
            echo "ERROR: GitHub CLI authentication or network is not available. Skipping Flatpak installation/update."
            exit 0
          fi

          for app in "''${apps[@]}"; do
            filename="''${app}.flatpak"
            state_file="$HOME/.local/state/custom-flatpaks/''${filename}.state"
            
            echo "Checking if $app needs an update..."
            current_updatedAt=$(${pkgs.gh}/bin/gh release view v1.0.0 -R XiaoXioe/flatpak-packages --json assets --jq ".assets[] | select(.name == \"$filename\") | .updatedAt" 2>/dev/null || true)
            
            if [ -n "$current_updatedAt" ] && [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$current_updatedAt" ]; then
              if ${pkgs.flatpak}/bin/flatpak list --app | grep -q "$app"; then
                echo "$app is already installed and up-to-date. Skipping download."
                continue
              fi
            fi

            success=false
            attempt=0
            
            while [ $attempt -lt $MAX_RETRIES ]; do
              echo "Downloading $filename (Attempt $((attempt+1))/$MAX_RETRIES)..."
              
              # Gunakan gh untuk mengambil URL S3/Azure, lalu unduh dengan curl agar lebih stabil dan cepat
              apiUrl=$(${pkgs.gh}/bin/gh release view v1.0.0 -R XiaoXioe/flatpak-packages --json assets --jq ".assets[] | select(.name == \"$filename\") | .apiUrl" 2>/dev/null || true)
              
              if [ -n "$apiUrl" ]; then
                token=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)
                if [ -n "$token" ] && ${pkgs.curl}/bin/curl -L --fail -C - -H "Authorization: Bearer $token" -H "Accept: application/octet-stream" "$apiUrl" -o "$filename"; then
                  success=true
                  break
                else
                  echo "Download failed. Retrying in 3 seconds..."
                  sleep 3
                fi
              else
                echo "Failed to get API URL for $filename. Retrying in 3 seconds..."
                sleep 3
              fi
              
              attempt=$((attempt+1))
            done
            
            if [ "$success" = true ] && [ -s "$filename" ]; then
              echo "Installing $app..."
              if ${pkgs.flatpak}/bin/flatpak list --app | grep -q "$app"; then
                if ${pkgs.flatpak}/bin/flatpak install --user --reinstall -y "$filename"; then
                  if [ -n "$current_updatedAt" ]; then
                    echo "$current_updatedAt" > "$state_file"
                  fi
                else
                  echo "Warning: Update of $app failed."
                fi
              else
                if ${pkgs.flatpak}/bin/flatpak install --user -y "$filename"; then
                  if [ -n "$current_updatedAt" ]; then
                    echo "$current_updatedAt" > "$state_file"
                  fi
                else
                  echo "Warning: Installation of $app failed."
                fi
              fi
            else
              echo "ERROR: Failed to download $filename after $MAX_RETRIES attempts or file is corrupted."
            fi
          done
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
