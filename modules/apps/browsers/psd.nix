{
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.psd";
  description = "Profile Sync Daemon (PSD) for syncing browser profiles to RAM (tmpfs)";

  nixosConfig = {
    # Override profile-sync-daemon globally so systemd services pick it up natively
    nixpkgs.overlays = [
      (final: prev: {
        profile-sync-daemon = prev.profile-sync-daemon.overrideAttrs (oldAttrs: {
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

    # Increase XDG_RUNTIME_DIR (/run/user/1000) size to accommodate browser tmpfs profiles
    services.logind.settings.Login.RuntimeDirectorySize = "4G";

    # Install the (overlaid) profile-sync-daemon package so the CLI command is available
    environment.systemPackages = [ pkgs.profile-sync-daemon ];
  };

  hmConfig = _hmOpts: {
    # Custom browser definition files for user config directory
    xdg.configFile."psd/browsers/brave".text = ''
      DIRArr[0]="$HOME/.config/BraveSoftware/Brave-Browser"
      PSNAME="brave"
    '';

    xdg.configFile."psd/browsers/zen".text = ''
      DIRArr=()
      PSNAME="zen"

      if [[ -f "$HOME/.zen/profiles.ini" ]]; then
        while read -r line; do
          if [[ "$line" =~ ^[Pp]ath=(.*)$ ]]; then
            path="''${BASH_REMATCH[1]}"
            if [[ "$path" =~ ^/ ]]; then
              DIRArr+=("$path")
            else
              DIRArr+=("$HOME/.zen/$path")
            fi
          fi
        done < "$HOME/.zen/profiles.ini"
      fi
    '';

    # Declarative configuration file for Profile Sync Daemon
    xdg.configFile."psd/psd.conf".text = ''
      # Profile Sync Daemon (psd) configuration file
      # Managed declaratively via NixOS / Home Manager

      # Target browsers to sync to RAM (tmpfs)
      BROWSERS=(firefox chromium google-chrome brave zen)

      # Use standard tmpfs sync (no sudo/doas root requirement, 100% compatible with doas)
      USE_OVERLAYFS="no"

      # Keep backup copy of browser profiles before sync
      USE_BACKUPS="yes"
    '';
  };
}
