{
  pkgs,
  config,
  selfLib,
  ...
}:
let
  torBrowserPkg = selfLib.fetchCachePinned "tor_browser";

  torBrowserCustom =
    pkgs.runCommand "tor-browser-${torBrowserPkg.version or "custom"}"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out
        cp -rs --no-preserve=mode ${torBrowserPkg}/* $out/

        # Ensure distribution/policies.json is symlinked to sops-rendered policies
        rm -rf $out/share/tor-browser/distribution
        mkdir -p $out/share/tor-browser/distribution
        cp -rs --no-preserve=mode ${torBrowserPkg}/share/tor-browser/distribution/* $out/share/tor-browser/distribution/
        ln -sf /run/secrets/rendered/tor-browser-policies.json $out/share/tor-browser/distribution/policies.json

        # Enable per-user runtime policy loading in defaults/pref
        rm -rf $out/share/tor-browser/defaults/pref
        mkdir -p $out/share/tor-browser/defaults/pref
        cp -rs --no-preserve=mode ${torBrowserPkg}/share/tor-browser/defaults/pref/* $out/share/tor-browser/defaults/pref/
        cat << 'EOF' > $out/share/tor-browser/defaults/pref/01-peruser.js
        pref("toolkit.policies.perUserDir", true);
        EOF

        # Re-wrap bin/tor-browser
        rm -f $out/bin/tor-browser
        makeWrapper $out/share/tor-browser/firefox $out/bin/tor-browser \
          --set FONTCONFIG_FILE "$out/share/tor-browser/fonts/fonts.conf" \
          --set-default MOZ_ENABLE_WAYLAND 1 \
          --run 'mkdir -p "''${XDG_RUNTIME_DIR:-/run/user/$UID}/firefox"' \
          --run 'ln -sf /run/secrets/rendered/tor-browser-policies.json "''${XDG_RUNTIME_DIR:-/run/user/$UID}/firefox/policies.json"'
      '';
in
selfLib.mkModule {
  name = "apps.browsers.tor-browser";
  description = "Tor Browser configuration with sops-nix encrypted bookmarks";

  preservation = {
    userDirectories = [
      ".cache/tor project"
      ".tor project"
    ];
  };

  hmConfig = {
    home.packages = [ torBrowserCustom ];
  };

  nixosConfig = {
    environment.etc."tor-browser/policies/policies.json".source =
      config.sops.templates."tor-browser-policies.json".path;

    sops.secrets."tor-browser-bookmarks" = {
      format = "binary";
      sopsFile = ./tor-bookmarks.enc;
      mode = "0444";
    };

    sops.templates."tor-browser-policies.json" = {
      owner = config.my.user.name;
      mode = "0644";
      content =
        builtins.replaceStrings
          [ ''"__BOOKMARKS__"'' ]
          [
            config.sops.placeholder."tor-browser-bookmarks"
          ]
          (
            builtins.toJSON {
              policies.Bookmarks = "__BOOKMARKS__";
            }
          );
    };
  };
}
