{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.ollama-to-llama";
  description = "Llama.cpp wrapper from Ollama Modelfiles";

  hmConfig = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "ollama-to-llama";
        runtimeInputs = [ pkgs.gawk pkgs.coreutils ];
        text = ''
          if ! command -v ollama &> /dev/null; then echo "Error: ollama not found."; exit 1; fi
          LLAMA_CMD="llama"
          if ! command -v "$LLAMA_CMD" &> /dev/null; then LLAMA_CMD="llama-cli"; fi
          ollama ls
          mapfile -t models < <(ollama ls | awk 'NR>1 {print $1}')
          PS3="Nomor model: "
          select model in "''${models[@]}"; do
            if [ -n "$model" ]; then
              llama_args=("-cnv" "--color" "auto")
              while IFS= read -r line; do
                if [[ "$line" == FROM* ]]; then llama_args+=("-m" "''${line#FROM }");
                elif [[ "$line" == PARAMETER* ]]; then
                  read -r _ key value <<< "$line"
                  case "$key" in num_ctx) llama_args+=("-c" "$value") ;; num_gpu) llama_args+=("-ngl" "$value") ;; esac
                fi
              done <<< "$(ollama show "$model" --modelfile)"
              "$LLAMA_CMD" "''${llama_args[@]}"
              break
            fi
          done
        '';
      })
    ];
  };
}
