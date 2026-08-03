{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.zapret";
  description = "Zapret2 anti-DPI bypass service (v2.x Lua Engine)";

  nixosConfig =
    { pkgs, lib, ... }:
    let
      # Override pkgs.zapret2 to the latest commit on bol-van/zapret2 main branch
      zapret2 = pkgs.zapret2.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = "2026-07-22-bb042f7";
          src = pkgs.fetchFromGitHub {
            owner = "bol-van";
            repo = "zapret2";
            rev = "bb042f734e6e444e138b581624b1c5a4d30513ce";
            hash = "sha256-Hf0Cp1tha5kX8lvOYQYJPDE5c2fRt8o6vM7jaHB2m0U=";
          };
          postInstall = (oldAttrs.postInstall or "") + ''
            cp -R files "$ZAPRET_BASE/"
          '';
          preBuild = ''
            makeFlagsArray+=("CFLAGS=-DZAPRET_GH_VER=v${finalAttrs.version} -DZAPRET_GH_HASH=bb042f734e6e")
          '';
        }
      );

      runnerScript = "${selfLib.mkApp pkgs "zapret2-runner"
        ''
          STATE_DIR="/var/lib/zapret2"
          SHARE_DIR="${zapret2}/share/zapret2"

          mkdir -p "$STATE_DIR"
          cd "$STATE_DIR"

          blob_args=""
          if [ -d "$SHARE_DIR/files/fake" ]; then
            for blob in "$SHARE_DIR"/files/fake/*.bin; do
              if [ -f "$blob" ]; then
                raw_name=$(basename "$blob" .bin)
                name=$(echo "$raw_name" | tr '-' '_')
                # Skip built-in C blobs fake_default_tls and fake_default_http
                if [ "$name" != "fake_default_tls" ] && [ "$name" != "fake_default_http" ]; then
                  blob_args="$blob_args --blob=$name:@$blob"
                fi
              fi
            done
          fi

          # shellcheck disable=SC2086
          exec ${zapret2}/bin/nfqws2 \
            --pidfile=/run/nfqws2.pid \
            --qnum=200 \
            $blob_args \
            --lua-init="@$SHARE_DIR/lua/zapret-lib.lua" \
            --lua-init="@$SHARE_DIR/lua/zapret-antidpi.lua" \
            --filter-tcp=80,443 \
            --filter-l7=tls,http \
            --lua-desync=fake:blob=fake_default_tls:tcp_md5
        ''
        [
          pkgs.coreutils
          zapret2
        ]
      }";
    in
    {
      systemd.services.zapret2 = {
        description = "Zapret2 anti-DPI daemon (nfqws2)";
        after = [ "network.target" ];
        # Disabled auto-start on boot by clearing wantedBy for manual activation.
        # User can start/stop manually using: sudo systemctl start zapret2
        wantedBy = lib.mkForce [ ];
        restartIfChanged = false;

        serviceConfig = {
          Type = "simple";
          ExecStart = runnerScript;
          PIDFile = "/run/nfqws2.pid";
          WorkingDirectory = "/var/lib/zapret2";
          StateDirectory = "zapret2";
          Restart = "on-failure";
          RestartSec = "5s";
          ProtectSystem = "full";
          ProtectHome = true;
          PrivateTmp = true;
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
          ];
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
          ];
        };
      };
    };
}
