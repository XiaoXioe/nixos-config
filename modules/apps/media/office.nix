{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.media.office";
  description = "Office applications bundle";
  # options = {
  #   flatpak = {
  #     enable = lib.mkOption {
  #       type = lib.types.bool;
  #       default = true;
  #       description = "Whether to use Flatpak for all office applications by default.";
  #     };
  #   };
  # };

  hmConfig =
    hmOpts:
    let
      lib = hmOpts.lib;
    in
    {
      home.sessionVariables = {
        MOZ_LEGACY_PROFILES = "1";
      };
      home.activation.copyThunderbirdProfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -L "$HOME/.thunderbird/profiles.ini" ]; then
          real_file=$(readlink -f "$HOME/.thunderbird/profiles.ini")
          rm -f "$HOME/.thunderbird/profiles.ini"
          cp "$real_file" "$HOME/.thunderbird/profiles.ini"
          chmod 644 "$HOME/.thunderbird/profiles.ini"
          
          # Paksa agar asosiasi instalasi ([Install...]) di profiles.ini selalu mengarah ke profil 'default'
          sed -i 's/^Default=[^1].*/Default=default/g' "$HOME/.thunderbird/profiles.ini"
        fi
      '';
    };

  flatpakCfg =
    let
      thunderbirdConfig = {
        enable = true;
        overrides = {
          Environment = {
            MOZ_LEGACY_PROFILES = "1";
          };
        };
        symlinks = [
          {
            host = ".thunderbird";
            guest = ".thunderbird";
          }
        ];
        nativePkgs = pkgs.thunderbird;
        hmProgram = {
          name = "thunderbird";
          extraConfig = {
            profiles = {
              default = {
                isDefault = true;
                settings = {
                  # --- TEMPLATE DEFAULT UNTUK AKUN BARU ---
                  "mail.server.default.offline_download" = false;
                  "mail.server.default.autosync_max_age_days" = 1; # Batas sinkronisasi maksimal 1 hari
                  "mail.server.default.limit_offline_message_size" = true;
                  "mail.server.default.max_size" = 50;
                  "mail.server.default.check_time" = 30;
                  "mail.server.default.check_new_mail" = true;

                  # --- OVERRIDE UNTUK SERVER 1 (JIKA ADA) ---
                  "mail.server.server1.offline_download" = false;
                  "mail.server.server1.autosync_max_age_days" = 1;
                  "mail.server.server1.limit_offline_message_size" = true;
                  "mail.server.server1.max_size" = 50;
                  "mail.server.server1.check_time" = 30;
                  "mail.server.server1.check_new_mail" = true;

                  # --- OVERRIDE UNTUK SERVER 2 (AKUN GMAIL AKTIF ANDA) ---
                  "mail.server.server2.offline_download" = false;
                  "mail.server.server2.autosync_max_age_days" = 1;
                  "mail.server.server2.limit_offline_message_size" = true;
                  "mail.server.server2.max_size" = 50;
                  "mail.server.server2.check_time" = 30;
                  "mail.server.server2.check_new_mail" = true;
                  "mail.server.server2.daysToKeepHdrs" = 7; # Hapus pesan setelah 7 hari
                  "mail.server.server2.retainBy" = 2; # Retensi berdasarkan umur pesan (age)

                  # --- PREFERENSI GLOBAL & KINERJA ---
                  "mailnews.database.global.indexer.enabled" = false;
                  "datareporting.healthreport.uploadEnabled" = false;
                  "toolkit.telemetry.enabled" = false;
                };
              };
            };
          };
        };
      };
    in
    {
      "eu.betterbird.Betterbird" = thunderbirdConfig;

      "org.pwmt.zathura" = {
        enable = true;
        symlinks = [
          {
            host = ".local/share/zathura";
            guest = "data/zathura";
          }
        ];
        nativePkgs = pkgs.zathura;
      };

      "org.onlyoffice.desktopeditors" = {
        enable = true;
        symlinks = [
          {
            host = ".config/onlyoffice";
            guest = "config/onlyoffice";
          }
          {
            host = ".local/share/onlyoffice";
            guest = "data/onlyoffice";
          }
        ];
        nativePkgs = pkgs.onlyoffice-desktopeditors;
        hmProgram = {
          name = "onlyoffice";
          extraConfig = {
            settings = {
              UITheme = "theme-contrast-dark";
            };
          };
        };
      };
    };
}
