{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.custompkgs.ollama-to-llama;

  ollama-to-llama-pkg = pkgs.writeShellApplication {
    name = "ollama-to-llama"; # Silakan ubah nama perintah ini jika ingin lebih singkat

    # Menyuntikkan dependensi utama.
    runtimeInputs = [
      pkgs.gawk
      pkgs.coreutils
    ];

    text = ''
      # Pastikan ollama bisa diakses untuk membaca Modelfile
      if ! command -v ollama &> /dev/null; then
          echo "❌ Error: Perintah 'ollama' tidak ditemukan."
          exit 1
      fi

      # Setel nama perintah llama
      LLAMA_CMD="llama"

      # Fallback pintar ala Nix: Jika 'llama' tidak ada, cari 'llama-cli' bawaan pkgs.llama-cpp
      if ! command -v "$LLAMA_CMD" &> /dev/null; then
          if command -v llama-cli &> /dev/null; then
              LLAMA_CMD="llama-cli"
          else
              echo "❌ Error: Perintah '$LLAMA_CMD' atau 'llama-cli' tidak ditemukan."
              exit 1
          fi
      fi

      echo "============================================================"
      echo "      DAFTAR MODEL OLLAMA (AKAN DIEKSEKUSI VIA LLAMA)       "
      echo "============================================================"
      ollama ls
      echo "============================================================"
      echo ""

      # Catatan: Semua penggunaan tanda kurung kurawal Bash di-escape dengan ''${...}
      mapfile -t models < <(ollama ls | awk 'NR>1 {print $1}')

      if [ ''${#models[@]} -eq 0 ]; then
          echo "Tidak ada model yang ditemukan."
          exit 1
      fi

      PS3="👉 Masukkan nomor model yang ingin dijalankan: "

      select model in "''${models[@]}"; do
          if [ -n "$model" ]; then
              echo -e "\n🔍 Mengekstrak konfigurasi dari Ollama Modelfile ($model)..."

              llama_args=("-cnv" "--color" "auto")
              model_path=""

              # State mesin untuk menangani multi-line string
              in_block=""
              block_content=""
              quote_type=""

              while IFS= read -r line || [[ -n "$line" ]]; do

                  # 1. JIKA SEDANG BERADA DI DALAM BLOK MULTI-LINE
                  if [[ -n "$in_block" ]]; then
                      # Cek apakah baris ini mengandung penutup quote (" atau """)
                      if [[ "$line" == *"$quote_type" ]]; then
                          # Hapus penutup quote dari akhir baris
                          line_content="''${line%"$quote_type"}"

                          if [[ -n "$line_content" ]]; then
                              if [[ -z "$block_content" ]]; then
                                  block_content="$line_content"
                              else
                                  block_content+=$'\n'"$line_content"
                              fi
                          fi

                          # Lempar ke llama_args jika itu SYSTEM
                          if [[ "$in_block" == "SYSTEM" ]]; then
                              llama_args+=("--system-prompt" "$block_content")
                          elif [[ "$in_block" == "TEMPLATE" ]]; then
                              :
                          fi

                          # Reset state machine
                          in_block=""
                          block_content=""
                          quote_type=""
                      else
                          # Masih di dalam blok, tambahkan baris beserta enter (\n)
                          if [[ -z "$block_content" ]]; then
                              block_content="$line"
                          else
                              block_content+=$'\n'"$line"
                          fi
                      fi
                      continue
                  fi

                  # 2. DETEKSI AWAL BLOK MULTI-LINE DENGAN TRIPLE QUOTES (""")
                  if [[ "$line" =~ ^(SYSTEM|TEMPLATE)[[:space:]]+(\"\"\")(.*)$ ]]; then
                      in_block="''${BASH_REMATCH[1]}"
                      quote_type='"""'
                      content="''${BASH_REMATCH[3]}"

                      # Cek apakah langsung ditutup di baris yang sama (one-liner)
                      if [[ "$content" == *'"""' ]]; then
                          content="''${content%'"""'}"
                          if [[ "$in_block" == "SYSTEM" ]]; then llama_args+=("--system-prompt" "$content"); fi
                          in_block=""
                      else
                          block_content="$content"
                      fi
                      continue

                  # 3. DETEKSI AWAL BLOK MULTI-LINE DENGAN SINGLE DOUBLE QUOTE (")
                  elif [[ "$line" =~ ^(SYSTEM|TEMPLATE)[[:space:]]+(\")(.*)$ ]]; then
                      in_block="''${BASH_REMATCH[1]}"
                      quote_type='"'
                      content="''${BASH_REMATCH[3]}"

                      if [[ "$content" == *'"' ]]; then
                          content="''${content%\"}"
                          if [[ "$in_block" == "SYSTEM" ]]; then llama_args+=("--system-prompt" "$content"); fi
                          in_block=""
                      else
                          block_content="$content"
                      fi
                      continue
                  fi

                  # 4. PARSING BARIS NORMAL (Single-Line)
                  if [[ "$line" == FROM* ]]; then
                      model_path="''${line#FROM }"
                      llama_args+=("-m" "$model_path")
                  elif [[ "$line" =~ ^SYSTEM[[:space:]]+(.*)$ ]]; then
                      llama_args+=("--system-prompt" "''${BASH_REMATCH[1]}")
                  elif [[ "$line" == PARAMETER* ]]; then
                    read -r _ key value <<< "$line"
                    case "$key" in
                          num_ctx)        llama_args+=("-c" "$value") ;;
                          num_gpu)        llama_args+=("-ngl" "$value") ;;
                          num_thread)     llama_args+=("-t" "$value") ;;
                          temperature)    llama_args+=("--temp" "$value") ;;
                          top_k)          llama_args+=("--top-k" "$value") ;;
                          top_p)          llama_args+=("--top-p" "$value") ;;
                          min_p)          llama_args+=("--min-p" "$value") ;;
                          repeat_penalty) llama_args+=("--repeat-penalty" "$value") ;;
                          stop)           llama_args+=("-r" "$value") ;;
                      esac
                  fi
              done <<< "$(ollama show "$model" --modelfile)"

              # Validasi ketersediaan file GGUF
              if [ -z "$model_path" ] || [ ! -f "$model_path" ]; then
                  echo "❌ Error: File GGUF ($model_path) tidak ditemukan."
                  break
              fi

              echo "🚀 Command: $LLAMA_CMD ''${llama_args[*]}"
              echo -e "------------------------------------------------------------\n"

              # Eksekusi llama
              "$LLAMA_CMD" "''${llama_args[@]}"
              break
          else
              echo "❌ Pilihan tidak valid."
          fi
      done
    '';
  };
in
{
  options.my.custompkgs.ollama-to-llama = {
    enable = lib.mkEnableOption "Wrapper script untuk menjalankan Llama.cpp dengan modelfile dari Ollama";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      ollama-to-llama-pkg
    ];
  };
}
