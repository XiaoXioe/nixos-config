{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.agy-profile";
  description = "Multi-account profile launcher for Antigravity CLI";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "doas-agent";
        runtimeInputs = [
          pkgs.openssh
          pkgs.coreutils
        ];
        text = ''
          # Escaped arguments for safe remote execution
          QARGS=""
          for arg in "$@"; do
            QARGS="$QARGS $(printf '%q' "$arg")"
          done

          # Execute via SSH to localhost to escape bubblewrap PR_SET_NO_NEW_PRIVS restriction.
          # The remote end reads /run/secrets/doas-password directly to prevent exposing
          # the password in the process list (ps) on either the local or remote side.
          exec ssh -F /dev/null -i /home/klein-moretti/.ssh/id_ed25519 -o StrictHostKeyChecking=no klein-moretti@localhost \
            "env CMD_ARGS=$(printf '%q' "$QARGS") bash -c '
              DOAS_PASS_FILE=/run/secrets/doas-password
              if [ ! -f \"\$DOAS_PASS_FILE\" ]; then
                echo \"doas-agent: secret file tidak ditemukan: \$DOAS_PASS_FILE\" >&2
                exit 1
              fi
              if command -v doas >/dev/null 2>&1; then
                (sleep 0.3; cat \"\$DOAS_PASS_FILE\") | script -q -c \"doas \$CMD_ARGS\" /dev/null
              else
                cat \"\$DOAS_PASS_FILE\" | sudo -S -p \"\" \$CMD_ARGS
              fi
            '"
        '';
      })

      (pkgs.writeShellApplication {
        name = "agy-profile";
        runtimeInputs = [
          pkgs.bubblewrap
          pkgs.coreutils
        ];
        text = ''
          REAL_HOME="$(eval echo "~$(whoami)")"
          AGY_DIR="$REAL_HOME/.gemini/antigravity-cli"
          CRED_DIR_BASE="$AGY_DIR/credentials"

          list_profiles() {
              if [ -d "$CRED_DIR_BASE" ]; then
                  echo "Daftar akun/profile yang tersedia:"
                  for d in "$CRED_DIR_BASE"/*/; do
                      [ -d "$d" ] && echo "  - $(basename "$d")"
                  done
              else
                  echo "Belum ada akun/profile yang terdaftar."
              fi
          }

          # Tanpa argumen: tampilkan usage + daftar akun
          if [ $# -eq 0 ]; then
              echo "Penggunaan: agy-profile <nama_profile>"
              echo ""
              list_profiles
              exit 1
          fi

          # Flag --list / -l / list: tampilkan daftar akun saja
          case "$1" in
              -l|--list|list)
                  list_profiles
                  exit 0
                  ;;
          esac

          PROFILE_NAME="$1"
          CRED_DIR="$CRED_DIR_BASE/$PROFILE_NAME"

          # Pastikan direktori credentials ada
          if [ ! -d "$CRED_DIR" ]; then
              echo "Profile '$PROFILE_NAME' belum ada. Membuat direktori credentials..."
              mkdir -p "$CRED_DIR"
              echo "Jalankan ulang setelah login pertama untuk menyimpan token."
          fi

          # Pastikan file credentials placeholder ada (agar bind mount bisa bekerja)
          for f in antigravity-oauth-token installation_id jetski_state.pbtxt; do
              [ ! -f "$CRED_DIR/$f" ] && touch "$CRED_DIR/$f"
          done

          echo "Menjalankan agy untuk profile: $PROFILE_NAME (namespace mode)"
          exec bwrap \
              --dev-bind / / \
              --bind "$CRED_DIR/antigravity-oauth-token" "$AGY_DIR/antigravity-oauth-token" \
              --bind "$CRED_DIR/installation_id" "$AGY_DIR/installation_id" \
              --bind "$CRED_DIR/jetski_state.pbtxt" "$AGY_DIR/jetski_state.pbtxt" \
              --setenv DBUS_SESSION_BUS_ADDRESS unix:path=/dev/null \
              --die-with-parent \
              agy
        '';
      })
    ];
  };
}
