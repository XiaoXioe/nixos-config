{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.ollama-to-llama";
  description = "Llama.cpp wrapper from Ollama Modelfiles";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "ollama-to-llama";
        runtimeInputs = [
          pkgs.gawk
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          if ! command -v ollama &> /dev/null; then
              echo "Error: Perintah 'ollama' tidak ditemukan."
              exit 1
          fi

          LLAMA_CMD="llama"

          if ! command -v "$LLAMA_CMD" &> /dev/null; then
              if command -v llama-cli &> /dev/null; then
                  LLAMA_CMD="llama-cli"
              else
                  echo "Error: Perintah '$LLAMA_CMD' atau 'llama-cli' tidak ditemukan."
                  exit 1
              fi
          fi

          echo "============================================================"
          echo "      DAFTAR MODEL OLLAMA (AKAN DIEKSEKUSI VIA LLAMA)       "
          echo "============================================================"
          ollama ls
          echo "============================================================"
          echo ""

          mapfile -t models < <(ollama ls | awk 'NR>1 {print $1}')

          if [ ''${#models[@]} -eq 0 ]; then
              echo "Tidak ada model yang ditemukan."
              exit 1
          fi

          PS3="Masukkan nomor model yang ingin dijalankan: "

          select model in "''${models[@]}"; do
              if [ -n "$model" ]; then
                  echo -e "\nMengekstrak konfigurasi dari Ollama Modelfile ($model)..."

                  llama_args=("-cnv" "--color" "auto")
                  model_path=""

                  in_block=""
                  block_content=""
                  quote_type=""

                  while IFS= read -r line || [[ -n "$line" ]]; do
                      if [[ -n "$in_block" ]]; then
                          if [[ "$line" == *"$quote_type" ]]; then
                              line_content="''${line%"$quote_type"}"

                              if [[ -n "$line_content" ]]; then
                                  if [[ -z "$block_content" ]]; then
                                      block_content="$line_content"
                                  else
                                      block_content+=$'\n'"$line_content"
                                  fi
                              fi

                              if [[ "$in_block" == "SYSTEM" ]]; then
                                  llama_args+=("--system-prompt" "$block_content")
                              elif [[ "$in_block" == "TEMPLATE" ]]; then
                                  :
                              fi

                              in_block=""
                              block_content=""
                              quote_type=""
                          else
                              if [[ -z "$block_content" ]]; then
                                  block_content="$line"
                              else
                                  block_content+=$'\n'"$line"
                              fi
                          fi
                          continue
                      fi

                      if [[ "$line" =~ ^(SYSTEM|TEMPLATE)[[:space:]]+(\"\"\")(.*)$ ]]; then
                          in_block="''${BASH_REMATCH[1]}"
                          quote_type='"""'
                          content="''${BASH_REMATCH[3]}"

                          if [[ "$content" == *'"""' ]]; then
                              content="''${content%'"""'}"
                              if [[ "$in_block" == "SYSTEM" ]]; then llama_args+=("--system-prompt" "$content"); fi
                              in_block=""
                          else
                              block_content="$content"
                          fi
                          continue

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

                      if [[ "$line" == FROM* ]]; then
                          model_path="''${line#FROM }"
                          if [ ! -f "$model_path" ]; then
                              if [[ "$model_path" =~ ^sha256[-:] ]]; then
                                  blob_name="''${model_path//:/-}"
                                  for base_dir in "''${OLLAMA_MODELS:-$HOME/.ollama/models}" "/usr/share/ollama/.ollama/models" "/var/lib/ollama/models"; do
                                      if [ -f "$base_dir/blobs/$blob_name" ]; then
                                          model_path="$base_dir/blobs/$blob_name"
                                          break
                                      fi
                                  done
                              else
                                  ref_path=$(echo "$model_path" | xargs)
                                  if [[ "$ref_path" == *:* ]]; then
                                      tag="''${ref_path##*:}"
                                      model_and_ns="''${ref_path%:*}"
                                  else
                                      tag="latest"
                                      model_and_ns="$ref_path"
                                  fi
                                  if [[ "$model_and_ns" == */* ]]; then
                                      ns="''${model_and_ns%/*}"
                                      model_name="''${model_and_ns##*/}"
                                  else
                                      ns="library"
                                      model_name="$model_and_ns"
                                  fi
                                  found_blob=""
                                  for base_dir in "''${OLLAMA_MODELS:-$HOME/.ollama/models}" "/usr/share/ollama/.ollama/models" "/var/lib/ollama/models"; do
                                      manifest_file="$base_dir/manifests/registry.ollama.ai/$ns/$model_name/$tag"
                                      if [ -f "$manifest_file" ]; then
                                          digest=$(jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$manifest_file" 2>/dev/null || true)
                                          if [ -n "$digest" ]; then
                                              blob_name="''${digest//:/-}"
                                              if [ -f "$base_dir/blobs/$blob_name" ]; then
                                                  found_blob="$base_dir/blobs/$blob_name"
                                                  break
                                              fi
                                          fi
                                      fi
                                  done
                                  if [ -n "$found_blob" ]; then
                                      model_path="$found_blob"
                                  fi
                              fi
                          fi
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

                  if [ -z "$model_path" ] || [ ! -f "$model_path" ]; then
                      echo "Error: File GGUF ($model_path) tidak ditemukan."
                      break
                  fi

                  echo "Command: $LLAMA_CMD ''${llama_args[*]}"
                  echo -e "------------------------------------------------------------\n"

                  "$LLAMA_CMD" "''${llama_args[@]}"
                  break
              else
                  echo "Pilihan tidak valid."
              fi
          done
        '';
      })
    ];
  };
}
