{
  config,
  pkgs,
  lib,
  selfLib,
  allUsers,
  hostName,
  ...
}:
let
  cfg = config.my.system.rebuild-wrapper;

  userList = lib.mapAttrsToList (name: _: name) allUsers;

  # Mendefinisikan script sebagai paket tersendiri
  rebuild-all-pkg = pkgs.writeShellScriptBin "rebuild-all" ''
    set -e

    # --- DEFAULTS ---
    DO_SYSTEM=true
    DO_HOME=true
    SPECIFIC_USER=""

    # --- PARSING OPSI ---
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -s|--system)
          DO_SYSTEM=true
          DO_HOME=false
          shift
          ;;
        -u|--user)
          DO_SYSTEM=false
          DO_HOME=true
          if [ -n "$2" ] && [[ "$2" != -* ]]; then
            SPECIFIC_USER="$2"
            shift 2
          else
            echo "❌ Error: Argumen untuk $1 hilang atau tidak valid."
            exit 1
          fi
          ;;
        -a|--all)
          DO_SYSTEM=true
          DO_HOME=true
          shift
          ;;
        -h|--help)
          echo "Penggunaan: rebuild-all [OPSI]"
          echo "Opsi:"
          echo "  -a, --all          Rebuild sistem dan semua user (Default)"
          echo "  -s, --system       Rebuild HANYA sistem NixOS"
          echo "  -u, --user <nama>  Rebuild HANYA Home Manager untuk user spesifik"
          echo "  -h, --help         Tampilkan bantuan ini"
          exit 0
          ;;
        *)
          echo "❌ Opsi tidak dikenal: $1"
          echo "Gunakan --help untuk melihat daftar opsi."
          exit 1
          ;;
      esac
    done

    echo "🚀 Memulai Proses Rebuild..."

    SOURCE_DIR=$(pwd)
    if [ ! -f "$SOURCE_DIR/flake.nix" ]; then
        SOURCE_DIR="/home/klein-moretti/nixos-config"
    fi

    # ─── Helper: jalankan perintah, tampilkan debug lengkap jika gagal ───
    run_or_fail() {
      local label="$1"
      shift
      local tmplog
      tmplog=$(mktemp /tmp/rebuild-log.XXXXXX)

      set +e
      "$@" 2>&1 | tee "$tmplog"
      local exit_code=''${PIPESTATUS[0]}
      set -e

      if [ "$exit_code" -ne 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "❌  GAGAL: $label  (exit code: $exit_code)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # ── Cari .drv yang gagal dari output nh/nix ──
        local failed_drvs
        failed_drvs=$(grep -oP '/nix/store/[a-z0-9]+-[^ ]+\.drv' "$tmplog" | tail -5 || true)
        if [ -n "$failed_drvs" ]; then
          echo ""
          echo "🔍 Log build derivasi yang gagal:"
          echo "──────────────────────────────────────────────────"
          for drv in $failed_drvs; do
            echo "▶ $drv"
            ${pkgs.nix}/bin/nix log "$drv" 2>/dev/null | tail -40 || echo "  (tidak ada log tersedia)"
            echo ""
          done
        fi

        # ── Journal systemd: error saat aktivasi ──
        echo ""
        echo "📋 Systemd journal errors (saat booting/aktivasi ini):"
        echo "──────────────────────────────────────────────────"
        ${pkgs.systemd}/bin/journalctl -b --priority=err --lines=40 --no-pager 2>/dev/null || true

        echo ""
        echo "💡 Tips debug lanjutan:"
        echo "   • journalctl -b -p err -u <unit>  — log unit spesifik"
        echo "   • systemctl status <unit>          — status unit yang gagal"
        echo "   • nix log <path.drv>               — log build nix"
        echo ""

        rm -f "$tmplog"
        exit "$exit_code"
      fi

      rm -f "$tmplog"
    }

    # 1. Rebuild NixOS (Sistem)
    if [ "$DO_SYSTEM" = true ]; then
      echo "📦 [SISTEM] Membangun ulang NixOS..."
      run_or_fail "NixOS System Switch" ${pkgs.nh}/bin/nh os switch "$SOURCE_DIR"
    fi

    # 2. Rebuild Home Manager
    if [ "$DO_HOME" = true ]; then

      # Menentukan target user: satu user spesifik atau semuanya
      if [ -n "$SPECIFIC_USER" ]; then
        TARGET_USERS="$SPECIFIC_USER"
      else
        TARGET_USERS="${lib.concatStringsSep " " userList}"
      fi

      for user in $TARGET_USERS; do
        echo "🏠 [USER: $user] Membangun ulang Home Manager..."

        BACKUP_EXT="backup-$(date +%s)"

        if id "$user" >/dev/null 2>&1; then
          if [ "$USER" = "$user" ]; then
            run_or_fail "Home Manager ($user)" ${pkgs.nh}/bin/nh home switch -b "$BACKUP_EXT" "$SOURCE_DIR"
          else
            echo "   (Membangun paket aktivasi untuk $user...)"
            ACTIVATE_SCRIPT=$(nix build "$SOURCE_DIR#homeConfigurations.\"$user@${hostName}\".activationPackage" --no-link --print-out-paths)

            echo "   (Mengaktifkan konfigurasi untuk $user...)"
            sudo -u "$user" -H env HOME_MANAGER_BACKUP_EXT="$BACKUP_EXT" "$ACTIVATE_SCRIPT/activate"
          fi
        else
          echo "   (User $user tidak ditemukan di sistem ini. Melewati...)"
        fi
      done
    fi

    echo "✅ Selesai! Tugas rebuild yang diminta telah diperbarui."
  '';

in
{
  # Membuat opsi deklaratif untuk modul ini
  options.my.system.rebuild-wrapper = {
    enable = selfLib.mkBoolOpt false "Script otomatis untuk rebuild sistem dan user";
  };

  # Menerapkan konfigurasi hanya jika opsi enable diatur ke true
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      rebuild-all-pkg
    ];
  };
}
