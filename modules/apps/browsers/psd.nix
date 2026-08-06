{
  pkgs,
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.psd";
  description = "Profile Sync Daemon (PSD) for syncing browser profiles to RAM (tmpfs)";

  nixosConfig = {
    environment.systemPackages = [ pkgs.profile-sync-daemon ];

    services.logind.settings.Login = {
      RuntimeDirectorySize = "6G";
    };

    # Allow passwordless execution of psd-overlay-helper for sudo and sudo-rs
    security.sudo.extraRules = [
      {
        users = [ config.my.user.name ];
        commands = [
          {
            command = "${pkgs.profile-sync-daemon}/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/etc/profiles/per-user/${config.my.user.name}/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    security.sudo-rs.extraRules = [
      {
        users = [ config.my.user.name ];
        commands = [
          {
            command = "${pkgs.profile-sync-daemon}/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/etc/profiles/per-user/${config.my.user.name}/bin/psd-overlay-helper";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Override profile-sync-daemon globally so systemd services pick it up natively
    nixpkgs.overlays = [
      (final: prev: {
        profile-sync-daemon = prev.profile-sync-daemon.overrideAttrs (
          _finalAttrs: oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              if [ -f common/profile-sync-daemon.in ]; then
                substituteInPlace common/profile-sync-daemon.in \
                  --replace-fail 'sudo -kn' 'sudo -n' \
                  --replace-fail 'sudo -n psd-overlay-helper' 'sudo -n /run/current-system/sw/bin/psd-overlay-helper' \
                  --replace-fail 'sudo psd-overlay-helper' 'sudo /run/current-system/sw/bin/psd-overlay-helper' \
                  --replace-fail 'find "''${DIR%/*}"' 'find "''${DIR%/*}" 2>/dev/null'
              fi
              if [ -f common/psd-overlay-helper ]; then
                substituteInPlace common/psd-overlay-helper \
                  --replace-fail 'sudo -u "$user"' 'runuser -u "$user" --'
              fi
            '';

            installPhase = (oldAttrs.installPhase or "") + ''
              cat << 'EOF' > $out/share/psd/browsers/brave
              DIRArr[0]="$HOME/.config/BraveSoftware/Brave-Browser"
              PSNAME="brave"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/chromium
              DIRArr[0]="$HOME/.config/chromium"
              PSNAME="chromium"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/torbrowser
              DIRArr[0]="$HOME/.local/share/torbrowser"
              PSNAME="firefox"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/zen
              DIRArr[0]="$HOME/.config/zen/$USER"
              DIRArr[1]="$HOME/.config/zen/$USER-01"
              PSNAME="zen"
              check_suffix="yes"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/firefox
              DIRArr[0]="$HOME/.config/mozilla/firefox/$USER"
              DIRArr[1]="$HOME/.config/mozilla/firefox/$USER-hardened"
              PSNAME="firefox"
              check_suffix="yes"
              EOF
            '';
          }
        );
      })
    ];
  };

  hmConfig = hmOpts: {
    services.psd = {
      enable = true;
      browsers = [
        "zen"
        "torbrowser"
        "brave"
        "chromium"
      ];
    };

    xdg.configFile."psd/psd.conf".text = hmOpts.lib.mkForce ''
      BROWSERS=(${hmOpts.lib.concatStringsSep " " hmOpts.config.services.psd.browsers})
      USE_BACKUP="${if hmOpts.config.services.psd.useBackup then "yes" else "no"}"
      BACKUP_LIMIT=${toString hmOpts.config.services.psd.backupLimit}
      USE_OVERLAYFS="yes"
    '';

    systemd.user.services.psd = {
      Service.TimeoutStopSec = "5m";
    };
  };
}
