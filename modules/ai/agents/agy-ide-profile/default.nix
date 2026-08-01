{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.agents.agy-ide-profile";
  description = "Multi-account profile launcher for Antigravity IDE";

  hmConfig = hmOpts: {
    home.packages = [
      (selfLib.mkApp pkgs "agy-ide-profile"
        ''
          REAL_HOME="$(eval echo "~$(whoami)")"
          AGY_IDE_DIR="$REAL_HOME/.gemini/antigravity-ide"
          CRED_DIR_BASE="$AGY_IDE_DIR/credentials"
          GLOBAL_STORAGE_DIR="$REAL_HOME/.antigravity-ide/User/globalStorage"
          ORIG_XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

          # SQLite keys auth
          KEY_TOKEN="antigravityUnifiedStateSync.oauthToken"
          KEY_STATUS="antigravityUnifiedStateSync.userStatus"
          KEY_PROFILE_URL="antigravity.profileUrl"

          list_profiles() {
              if [ -d "$CRED_DIR_BASE" ] && [ -n "$(ls -A "$CRED_DIR_BASE" 2>/dev/null)" ]; then
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
              echo "Penggunaan: agy-ide-profile <nama_profile>"
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
              echo "Profile '$PROFILE_NAME' belum ada. Membuat credentials baru..."
              mkdir -p "$CRED_DIR"
          fi

          # Pastikan profile punya state.vscdb
          if [ ! -f "$CRED_DIR/state.vscdb" ]; then
              if [ -d "$GLOBAL_STORAGE_DIR" ]; then
                  echo "Menyalin data awal globalStorage dari host..."
                  cp -r "$GLOBAL_STORAGE_DIR"/. "$CRED_DIR"/
                  # Hapus session keys dan secret keys lama agar user bisa login dengan akun baru
                  sqlite3 "$CRED_DIR/state.vscdb" \
                      "DELETE FROM ItemTable WHERE key IN ('$KEY_TOKEN', '$KEY_STATUS', '$KEY_PROFILE_URL') OR key LIKE 'secret://%';"
                  echo "Buka IDE dan login untuk profile ini."
              else
                  echo "Memulai dengan globalStorage kosong (IDE akan menginisialisasi otomatis)."
              fi
          fi

          # Buat XDG_RUNTIME_DIR terisolasi untuk profil ini agar multi-instance IPC tidak bertabrakan
          XDG_RUNTIME_DIR_PROFILE="/tmp/agy-ide-runtime-$PROFILE_NAME"
          mkdir -p "$XDG_RUNTIME_DIR_PROFILE"
          chmod 700 "$XDG_RUNTIME_DIR_PROFILE"

          # Tautkan Wayland display socket agar platform Wayland bisa berjalan
          if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "$ORIG_XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
              ln -sf "$ORIG_XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR_PROFILE/$WAYLAND_DISPLAY"
          fi

          echo "Menjalankan Antigravity IDE untuk profile: $PROFILE_NAME (namespace mode)"
          # Pastikan target mount point di host ada
          mkdir -p "$GLOBAL_STORAGE_DIR"

          exec bwrap \
              --dev-bind / / \
              --bind "$CRED_DIR" "$GLOBAL_STORAGE_DIR" \
              --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR_PROFILE" \
              --die-with-parent \
              antigravity-ide
        ''
        [
          pkgs.bubblewrap
          pkgs.sqlite
          pkgs.coreutils
        ]
      )
    ];
  };
}
