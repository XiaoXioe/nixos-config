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

  appInfo = selfLib.appVersions.betterbird;

  betterbirdDesktopItem = pkgs.makeDesktopItem {
    name = "eu.betterbird.Betterbird";
    desktopName = "Betterbird";
    genericName = "Email Client";
    comment = "Send and receive mail with Betterbird";
    exec = "betterbird %u";
    icon = "eu.betterbird.Betterbird";
    terminal = false;
    type = "Application";
    categories = [
      "Network"
      "Email"
      "News"
      "GTK"
    ];
    mimeTypes = [
      "message/rfc822"
      "x-scheme-handler/mailto"
      "text/calendar"
      "text/x-vcard"
    ];
    keywords = [
      "mail"
      "email"
      "betterbird"
      "thunderbird"
    ];
    startupWMClass = "eu.betterbird.Betterbird";
    startupNotify = true;
  };

  betterbirdNative = (selfLib.mkNativeApp pkgs) {
    name = "betterbird";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "betterbird";
    execPath = "betterbird/betterbird";
    binName = "betterbird";
    desktopItem = betterbirdDesktopItem;
    extraEnv = {
      MOZ_LEGACY_PROFILES = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
    extraUnwrappedInstall = ''
      icon_src="$out/opt/betterbird/betterbird/chrome/icons/default"
      for size in 16 22 24 32 48 64 128 256; do
        if [ -f "$icon_src/default''${size}.png" ]; then
          mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
          cp "$icon_src/default''${size}.png" "$out/share/icons/hicolor/''${size}x''${size}/apps/betterbird.png"
          cp "$icon_src/default''${size}.png" "$out/share/icons/hicolor/''${size}x''${size}/apps/eu.betterbird.Betterbird.png"
          cp "$icon_src/default''${size}.png" "$out/share/icons/hicolor/''${size}x''${size}/apps/thunderbird.png"
        fi
      done

      mkdir -p "$out/share/pixmaps"
      if [ -f "$icon_src/default256.png" ]; then
        cp "$icon_src/default256.png" "$out/share/pixmaps/betterbird.png"
        cp "$icon_src/default256.png" "$out/share/pixmaps/eu.betterbird.Betterbird.png"
        cp "$icon_src/default256.png" "$out/share/pixmaps/thunderbird.png"
      fi
    '';
    extraPostInstall = ''
      # Alias / symlink agar binary dapat dipanggil sebagai thunderbird maupun betterbird di terminal
      ln -sf "$out/bin/betterbird" "$out/bin/thunderbird"
    '';
  };
in
selfLib.mkModule {
  name = "apps.office.thunderbird";
  description = "Betterbird / Thunderbird email client with optimized native profiles";

  preservation = {
    userDirectories = [
      ".thunderbird"
    ];
  };

  nixosConfig =
    { config, ... }:
    {
      my.services.vmtouch.paths = [
        betterbirdNative
        "/home/${config.my.user.name}/.thunderbird"
      ];
    };

  hmConfig = {
    programs.thunderbird = {
      enable = true;
      package = betterbirdNative;
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

              # Startup & Default Client Check
              "mail.shell.checkDefaultClient" = false;
              "mail.shell.checkDefaultMail" = false;

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
}
