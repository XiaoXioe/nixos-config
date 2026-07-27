{
  selfLib,
  pkgs,
  lib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.thunderbird";
  description = "Thunderbird and Betterbird email client with optimized profiles";

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
          real_file=$(${pkgs.coreutils}/bin/readlink -f "$HOME/.thunderbird/profiles.ini")
          ${pkgs.coreutils}/bin/rm -f "$HOME/.thunderbird/profiles.ini"
          ${pkgs.coreutils}/bin/cp "$real_file" "$HOME/.thunderbird/profiles.ini"
          ${pkgs.coreutils}/bin/chmod 644 "$HOME/.thunderbird/profiles.ini"
          
          # Paksa agar asosiasi instalasi ([Install...]) di profiles.ini selalu mengarah ke profil 'default'
          ${pkgs.gnused}/bin/sed -i 's/^Default=[^1].*/Default=default/g' "$HOME/.thunderbird/profiles.ini"
        fi
      '';
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
              settings = {
                # --- TEMPLATE DEFAULT UNTUK AKUN BARU ---
                "mail.server.default.offline_download" = false;
                "mail.server.default.autosync_max_age_days" = 1; # Batas sinkronisasi maksimal 1 hari
                "mail.server.default.limit_offline_message_size" = true;
                "mail.server.default.max_size" = 50;
                "mail.server.default.check_time" = 30;
                "mail.server.default.check_new_mail" = true;
                "mail.server.default.max_cached_connections" = 1;

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

                # Opsi Snappiness & System Tray
                "mailnews.start_page.enabled" = false;
                "toolkit.cosmeticAnimations.enabled" = false;
                "mail.minimizeToTray" = true;

                # Pembersihan Penyimpanan Otomatis (Auto Compact)
                "mail.purge_threshhold_mb" = 20;
                "mail.prompt_purge_threshold" = false;

                # Unified Folders (Menampilkan Gabungan Semua Email/Inbox)
                "mail.folderpane.activeModes" = "0,1";
                "mail.folderpane.header.visible" = true;
              }
              // (builtins.listToAttrs (
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
