{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.auth-agent";
  description = "Secure GUI authentication AI agent root operations";

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;
    in
    {
      home.packages = [
        (selfLib.mkApp pkgs "auth-agent"
          ''
            # Escaped arguments for safe remote execution
            QARGS=""
            for arg in "$@"; do
              QARGS="$QARGS $(printf '%q' "$arg")"
            done

            # Execute via SSH to localhost to escape bubblewrap PR_SET_NO_NEW_PRIVS restriction.
            exec ssh -F /dev/null -i "$HOME/.ssh/id_ed25519" -o StrictHostKeyChecking=no "${user}@localhost" \
              "env CMD_ARGS=$(printf '%q' "$QARGS") bash -c '
                export WAYLAND_DISPLAY=wayland-1
                export XDG_RUNTIME_DIR=/run/user/\$(id -u)
                
                PASS=\$(zenity --entry --hide-text --title=\"Otorisasi AI (auth-agent)\" --text=\"Agent meminta akses root untuk menjalankan perintah:\\n\\n[ \$CMD_ARGS ]\\n\\nMasukkan password Anda:\" 2>/dev/null)
                
                if [ -z \"\$PASS\" ]; then
                  echo \"auth-agent: Otorisasi dibatalkan oleh pengguna.\" >&2
                  exit 1
                fi
                
                if command -v doas >/dev/null 2>&1; then
                  echo \"\$PASS\" | doas \$CMD_ARGS
                else
                  echo \"\$PASS\" | sudo -S -p \"\" \$CMD_ARGS
                fi
              '"
          ''
          [
            pkgs.openssh
            pkgs.coreutils
            pkgs.zenity
          ]
        )
      ];
    };
}
