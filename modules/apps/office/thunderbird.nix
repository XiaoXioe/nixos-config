{
  selfLib,
  pkgs,
  lib,
  ...
}:

let
  # Preset preferensi server mail yang dapat digunakan kembali secara DRY
  commonServerSettings = {
    offline_download = false;
    autosync_max_age_days = 1;
    limit_offline_message_size = true;
    max_size = 50;
    check_time = 30;
    check_new_mail = true;
  };

  # Helper function untuk menghasilkan preferensi server berdasarkan id server
  mkServerConfig =
    serverId: extraSettings:
    lib.mapAttrs' (name: value: lib.nameValuePair "mail.server.${serverId}.${name}" value) (
      commonServerSettings // extraSettings
    );
in
selfLib.mkModule {
  name = "apps.office.thunderbird";
  description = "Thunderbird and Betterbird email client with optimized profiles";

  preservation = {
    userDirectories = [
      ".thunderbird"
    ];
  };

  flatpakCfg = {
    "eu.betterbird.Betterbird" = {
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
              settings =
                (mkServerConfig "default" { })
                // (mkServerConfig "server1" { })
                // (mkServerConfig "server2" {
                  daysToKeepHdrs = 7;
                  retainBy = 2;
                })
                // {
                  # Preferensi Kinerja & Telemetri
                  "mailnews.database.global.indexer.enabled" = false;
                  "datareporting.healthreport.uploadEnabled" = false;
                  "toolkit.telemetry.enabled" = false;

                  # UI & System Tray
                  "mailnews.start_page.enabled" = false;
                  "toolkit.cosmeticAnimations.enabled" = false;
                  "mail.minimizeToTray" = true;

                  # Auto Compact Storage
                  "mail.purge_threshhold_mb" = 20;
                  "mail.prompt_purge_threshold" = false;

                  # Unified Folders
                  "mail.folderpane.activeModes" = "0,1";
                  "mail.folderpane.header.visible" = true;
                }
                // (lib.listToAttrs (
                  map (n: {
                    name = "mail.server.server${toString n}.max_cached_connections";
                    value = 1;
                  }) (lib.range 1 30)
                ));
            };
          };
        };
      };
    };
  };
}
