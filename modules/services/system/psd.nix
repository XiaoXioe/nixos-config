{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.psd;
in
{
  options.my.services.psd = {
    enable = selfLib.mkBoolOpt false "profile-sync-daemon configuration";
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = [
      (final: prev: {
        profile-sync-daemon = prev.profile-sync-daemon.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            mkdir -p $out/share/psd/browsers
            cat > $out/share/psd/browsers/brave <<'EOF'
            DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"
            PSNAME="brave"
            EOF
          '';

          postFixup = (old.postFixup or "") + ''
            sed -i "s|SHAREDIR=.*|SHAREDIR=\"$out/share/psd\"|" $out/bin/profile-sync-daemon
            # Fix find permission denied errors and improve performance by limiting find depth
            sed -i "s|-type d -name '*crashrecovery*'|-maxdepth 1 -type d -name '*crashrecovery*' 2>/dev/null|g" $out/bin/profile-sync-daemon
          '';
        });
      })
    ];

    # Aktifkan service psd
    services.psd.enable = true;
  };
}
