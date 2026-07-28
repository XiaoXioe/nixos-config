{
  pkgs,
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.psd";
  description = "Profile Sync Daemon (PSD) for syncing browser profiles to RAM (tmpfs)";

  nixosConfig = {
    # Allow passwordless execution of psd-overlay-helper for sudo and sudo-rs
    security.sudo.extraConfig = ''
      ${config.my.user.name} ALL=(ALL) NOPASSWD: ${pkgs.profile-sync-daemon}/bin/psd-overlay-helper
      ${config.my.user.name} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/psd-overlay-helper
    '';
    security.sudo-rs.extraConfig = ''
      ${config.my.user.name} ALL=(ALL) NOPASSWD: ${pkgs.profile-sync-daemon}/bin/psd-overlay-helper
      ${config.my.user.name} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/psd-overlay-helper
    '';

    # Override profile-sync-daemon globally so systemd services pick it up natively
    nixpkgs.overlays = [
      (final: prev: {
        profile-sync-daemon = prev.profile-sync-daemon.overrideAttrs (
          _finalAttrs: oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              if [ -f common/profile-sync-daemon.in ]; then
                substituteInPlace common/profile-sync-daemon.in \
                  --replace-fail 'sudo -kn' 'sudo -n' \
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
              PSNAME="zen"
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
    };

    xdg.configFile."psd/psd.conf".text = ''
      USE_OVERLAYFS="yes"
      USE_BACKUPS="false"
      BROWSERS=(firefox zen torbrowser brave chromium)
    '';
  };
}
