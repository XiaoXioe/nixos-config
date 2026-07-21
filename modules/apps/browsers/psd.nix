{
  pkgs,
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.psd";
  description = "Profile Sync Daemon (PSD) for syncing browser profiles to RAM (tmpfs)";

  nixosConfig =
    let
      psdOverlayHelperRules = [
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
          ];
        }
      ];
    in
    {
      # Allow passwordless execution of psd-overlay-helper for sudo-rs
      security.sudo-rs.extraRules = psdOverlayHelperRules;

      # Override profile-sync-daemon globally so systemd services pick it up natively
      nixpkgs.overlays = [
        (final: prev: {
          profile-sync-daemon = prev.profile-sync-daemon.overrideAttrs (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              if [ -f common/profile-sync-daemon.in ]; then
                substituteInPlace common/profile-sync-daemon.in \
                  --replace-fail 'sudo -kn' 'sudo -n'
              fi
              if [ -f common/psd-overlay-helper ]; then
                substituteInPlace common/psd-overlay-helper \
                  --replace-fail 'sudo -u' 'runuser -u'
              fi
            '';

            installPhase = (oldAttrs.installPhase or "") + ''
              cat << 'EOF' > $out/share/psd/browsers/brave
              DIRArr[0]="$HOME/.config/BraveSoftware/Brave-Browser"
              PSNAME="brave"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/zen
              DIRArr[0]="$HOME/.config/zen/$USER"
              PSNAME="zen"
              EOF

              cat << 'EOF' > $out/share/psd/browsers/firefox
              DIRArr[0]="$HOME/.config/mozilla/firefox/$USER"
              DIRArr[1]="$HOME/.config/mozilla/firefox/$USER-hardened"
              PSNAME="firefox"
              check_suffix="yes"
              EOF
            '';
          });
        })
      ];

      # Enable systemd user service for Profile Sync Daemon
      services.psd = {
        enable = true;
        resyncTimer = "1h";
      };

      # Prevent PSD from restarting during nixos rebuild/activation
      systemd.user.services.psd = {
        restartIfChanged = false;
        stopIfChanged = false;
      };
      systemd.user.services.psd-resync = {
        restartIfChanged = false;
        stopIfChanged = false;
      };

      # Increase XDG_RUNTIME_DIR (/run/user/1000) size to accommodate browser tmpfs profiles
      services.logind.settings.Login.RuntimeDirectorySize = "4G";

      # Install the (overlaid) profile-sync-daemon package so the CLI command is available
      environment.systemPackages = [ pkgs.profile-sync-daemon ];
    };

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;
    in
    {
      # Custom browser definition files for user config directory
      xdg.configFile."psd/browsers/brave".text = ''
        DIRArr[0]="$HOME/.config/BraveSoftware/Brave-Browser"
        PSNAME="brave"
      '';

      xdg.configFile."psd/browsers/firefox".text = ''
        DIRArr=()
        PSNAME="firefox"
        user="${user}"
        check_suffix="yes"

        if [[ -d "$HOME/.config/mozilla/firefox/$user" ]]; then
          DIRArr+=("$HOME/.config/mozilla/firefox/$user")
        fi
        if [[ -d "$HOME/.config/mozilla/firefox/$user-hardened" ]]; then
          DIRArr+=("$HOME/.config/mozilla/firefox/$user-hardened")
        fi
      '';

      xdg.configFile."psd/browsers/zen".text = ''
        DIRArr=()
        PSNAME="zen"
        user="${user}"

        if [[ -d "$HOME/.config/zen/$user" ]]; then
          DIRArr+=("$HOME/.config/zen/$user")
        fi

        if [[ -f "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" ]]; then
          while read -r line; do
            if [[ "$line" =~ ^[Pp]ath=(.*)$ ]]; then
              path="''${BASH_REMATCH[1]}"
              if [[ -d "$HOME/.config/zen/$path" ]]; then
                DIRArr+=("$HOME/.config/zen/$path")
              elif [[ -d "$HOME/.var/app/app.zen_browser.zen/.zen/$path" ]]; then
                DIRArr+=("$HOME/.var/app/app.zen_browser.zen/.zen/$path")
              fi
            fi
          done < "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini"
        fi

        if [[ ''${#DIRArr[@]} -gt 0 ]]; then
          readarray -t DIRArr < <(printf "%s\n" "''${DIRArr[@]}" | sort -u)
        fi
      '';

      # Declarative configuration file for Profile Sync Daemon
      xdg.configFile."psd/psd.conf".text = ''
        # Profile Sync Daemon (psd) configuration file
        # Managed declaratively via NixOS / Home Manager

        # Target browsers to sync to RAM (tmpfs)
        BROWSERS=(firefox brave zen)

        # Use OverlayFS sync so RAM tmpfs only stores delta changes (saving ~3GB of RAM)
        USE_OVERLAYFS="yes"

        # Keep backup copy of browser profiles before sync
        USE_BACKUPS="yes"
      '';
    };
}
