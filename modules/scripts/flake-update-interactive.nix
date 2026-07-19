{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.flake-update-interactive";
  description = "Interactive flake input updater using fzf and jq (nfui)";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "nfui";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.fzf
          pkgs.jq
          pkgs.nix
          pkgs.git
        ];
        text = ''
          # Helper untuk menampilkan help
          show_help() {
            echo "Nix Flake Update Interactive (nfui)"
            echo ""
            echo "Penggunaan:"
            echo "  nfui                     Menjalankan update untuk semua input flake secara interaktif"
            echo "  nfui <input1> <input2>   Menjalankan update secara terarah hanya untuk input yang ditentukan"
            echo "  nfui --restore           Menjalankan rollback interaktif untuk mengembalikan input tertentu"
            echo "  nfui --help              Menampilkan pesan bantuan ini"
          }

          # Cek parameter input CLI untuk restore atau help
          if [ "$#" -gt 0 ]; then
            case "$1" in
              --restore)
                if [ ! -f ".nfui-lock.bak" ]; then
                  echo "Error: Cadangan .nfui-lock.bak tidak ditemukan di direktori ini." >&2
                  exit 1
                fi

                echo "==> Menganalisis perbedaan lock file dengan cadangan..."
                # Bandingkan flake.lock saat ini dengan .nfui-lock.bak untuk melihat input mana yang berubah
                diff_inputs=$(jq -r '.nodes as $new | $old[0].nodes as $old_nodes | ($new | keys)[] | select($new[.].locked and $old_nodes[.].locked and ($new[.].locked.rev != $old_nodes[.].locked.rev or $new[.].locked.narHash != $old_nodes[.].locked.narHash))' --slurpfile old .nfui-lock.bak flake.lock || true)

                if [ -z "$diff_inputs" ]; then
                  echo "Tidak ada input yang berbeda dari cadangan. Tidak ada yang perlu di-rollback!"
                  exit 0
                fi

                # Menu restore interaktif menggunakan fzf
                exit_code=0
                selected=$(echo "$diff_inputs" | fzf --multi \
                  --prompt="Pilih input flake yang ingin di-rollback ke versi cadangan (TAB untuk menandai, ENTER untuk konfirmasi): " \
                  --header="Navigasi: PANAH | Rollback: TAB | Konfirmasi: ENTER (Esc/Ctrl-C untuk Batal)" \
                  --layout=reverse \
                  --height=50% \
                  --border) || exit_code=$?

                # Jika fzf dibatalkan
                if [ "''${exit_code:-0}" -ne 0 ]; then
                  echo "Rollback dibatalkan."
                  exit 0
                fi

                if [ -z "$selected" ]; then
                  echo "Tidak ada input yang dipilih untuk di-rollback."
                  exit 0
                fi

                # Konversi pilihan menjadi array
                readarray -t selected_inputs <<< "$selected"

                echo "==> Mengembalikan input terpilih ke versi cadangan..."
                jq_filter=""
                for input in "''${selected_inputs[@]}"; do
                  if [ -z "$jq_filter" ]; then
                    jq_filter=".nodes[\"$input\"] = \$old[0].nodes[\"$input\"]"
                  else
                    jq_filter="$jq_filter | .nodes[\"$input\"] = \$old[0].nodes[\"$input\"]"
                  fi
                done

                # Tulis menggunakan pengalihan cat untuk mempertahankan hak akses (permission mode) file flake.lock asli
                jq "$jq_filter" --slurpfile old .nfui-lock.bak flake.lock > flake.lock.tmp
                cat flake.lock.tmp > flake.lock
                rm -f flake.lock.tmp

                echo "===================================================="
                echo "Input berikut berhasil dikembalikan ke versi semula:"
                for input in "''${selected_inputs[@]}"; do
                  echo "  [x] $input"
                done
                echo "===================================================="
                exit 0
                ;;
              --help|-h)
                show_help
                exit 0
                ;;
            esac
          fi

          # Pastikan berada di dalam direktori repositori flake
          if [ ! -f "flake.nix" ]; then
            echo "Error: Berkas 'flake.nix' tidak ditemukan di direktori saat ini." >&2
            exit 1
          fi

          if [ "$#" -gt 0 ]; then
            echo "==> Menganalisis pembaruan input flake terarah: $*"
          else
            echo "==> Menganalisis pembaruan input flake (seluruhnya)..."
          fi

          # Cek jika ada cadangan lama dan flake.lock dalam keadaan kotor (uncommitted changes)
          # Kita tidak menimpa cadangan lama agar restore point pertama tidak hilang
          if [ -f ".nfui-lock.bak" ] && ! git diff --quiet flake.lock 2>/dev/null; then
            echo "==> Mempertahankan restore point lama di .nfui-lock.bak (ada perubahan uncommitted)."
          else
            cp flake.lock .nfui-lock.bak
          fi

          # Bersihkan log saat keluar
          trap 'rm -f update_output.log' EXIT

          # Jalankan update secara real untuk melihat pembaruan dan mengunduh data sekaligus
          # Kita meneruskan parameter "$@" (misalnya nama-nama input tertentu) jika ditentukan oleh pengguna
          if ! nix flake update "$@" 2>update_output.log; then
            echo "Error: Gagal menjalankan nix flake update. Mengembalikan lock file..." >&2
            cat update_output.log >&2
            cp .nfui-lock.bak flake.lock
            exit 1
          fi

          # Ekstrak daftar input yang berhasil di-update
          updated_inputs=$(grep -oE "• Updated input '[^']+'" update_output.log | cut -d"'" -f2 || true)

          if [ -z "$updated_inputs" ]; then
            echo "Semua input flake sudah up-to-date!"
            # Hapus cadangan jika lock file bersih (tidak ada perubahan baru dibanding versi awal)
            if git diff --quiet flake.lock 2>/dev/null; then
              rm -f .nfui-lock.bak
            fi
            exit 0
          fi

          # Tampilkan fzf menu interaktif berisi input yang telah diperbarui
          exit_code=0
          selected=$(echo "$updated_inputs" | fzf --multi \
            --prompt="Pilih pembaruan input flake yang ingin disimpan (TAB untuk memilih, ENTER untuk konfirmasi): " \
            --header="Navigasi: PANAH | Simpan Pembaruan: TAB | Konfirmasi: ENTER (Esc/Ctrl-C untuk Batal)" \
            --layout=reverse \
            --height=50% \
            --border) || exit_code=$?

          # Jika fzf dibatalkan (Esc atau Ctrl-C)
          if [ "''${exit_code:-0}" -ne 0 ]; then
            echo "Pembaruan dibatalkan. Mengembalikan lock file ke versi semula..."
            cp .nfui-lock.bak flake.lock
            exit 0
          fi

          # Jika tidak ada yang dipilih, kembalikan semuanya
          if [ -z "$selected" ]; then
            echo "Tidak ada input yang dipilih untuk diperbarui. Mengembalikan lock file ke versi semula..."
            cp .nfui-lock.bak flake.lock
            exit 0
          fi

          # Konversi pilihan menjadi array
          readarray -t selected_inputs <<< "$selected"

          # Cari input mana saja yang tidak terpilih (unselected) untuk dikembalikan
          unselected=()
          for input in $updated_inputs; do
            found=false
            for sel in "''${selected_inputs[@]}"; do
              if [ "$input" = "$sel" ]; then
                found=true
                break
              fi
            done
            if [ "$found" = false ]; then
              unselected+=("$input")
            fi
          done

          # Jika ada input yang tidak dipilih, kembalikan versinya via jq
          if [ "''${#unselected[@]}" -gt 0 ]; then
            echo "==> Mengembalikan input yang tidak dipilih ke versi semula..."
            jq_filter=""
            for input in "''${unselected[@]}"; do
              if [ -z "$jq_filter" ]; then
                jq_filter=".nodes[\"$input\"] = \$old[0].nodes[\"$input\"]"
              else
                jq_filter="$jq_filter | .nodes[\"$input\"] = \$old[0].nodes[\"$input\"]"
              fi
            done

            # Tulis menggunakan pengalihan cat untuk mempertahankan hak akses (permission mode) file flake.lock asli
            jq "$jq_filter" --slurpfile old .nfui-lock.bak flake.lock > flake.lock.tmp
            cat flake.lock.tmp > flake.lock
            rm -f flake.lock.tmp
          fi

          echo ""
          echo "===================================================="
          echo "Pembaruan input berikut berhasil disimpan di flake.lock:"
          for sel in "''${selected_inputs[@]}"; do
            echo "  [x] $sel"
          done

          if [ "''${#unselected[@]}" -gt 0 ]; then
            echo "Input berikut dikembalikan ke versi semula:"
            for uns in "''${unselected[@]}"; do
              echo "  [ ] $uns"
            done
          fi
          echo "===================================================="
          echo "Info: Jalankan 'nfui --restore' jika ingin me-rollback pembaruan tertentu secara interaktif nanti."
        '';
      })
    ];
  };
}
