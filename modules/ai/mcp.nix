{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Nix-native packaging of the npm ssh-mcp package as a fixed-output derivation
  ssh-mcp-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "ssh-mcp";
    version = "1.5.0";

    src =
      pkgs.runCommand "ssh-mcp-src"
        {
          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.cacert
          ];
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "sha256-MU6IiT+fDbx1smOBaLiAf4wEuh6c19coH5IPDK5zQ+Y=";
        }
        ''
          export HOME=$TMPDIR
          mkdir -p $out/lib
          cd $out/lib
          npm install --no-audit --no-fund --production ssh-mcp@${version}
        '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin $out/lib
      ln -s $src/lib/node_modules $out/lib/node_modules
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/ssh-mcp \
        --add-flags "$out/lib/node_modules/ssh-mcp/build/index.js"
    '';
  };

  codebase-memory-mcp-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "codebase-memory-mcp";
    version = "0.8.1";

    src = pkgs.fetchurl {
      url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/codebase-memory-mcp-linux-amd64.tar.gz";
      sha256 = "sha256-29O5Lqhw7yQLYwWfJr2hUBX3bvmXiTG+vDoPnQlHCXM=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.prelink
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp codebase-memory-mcp $out/bin/
      chmod +x $out/bin/codebase-memory-mcp
      execstack -c $out/bin/codebase-memory-mcp
    '';
  };

  google-colab-mcp-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "google-colab-mcp";
    version = "1.0.1";

    src = pkgs.runCommand "${pname}-src"
      {
        nativeBuildInputs = [
          pkgs.python313
          pkgs.cacert
        ];
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        outputHash = "sha256-Qm/B1ldhd+wec2YKBp8JOUUtfGd//tc8oI+D/B/uObI=";
      }
      ''
        export HOME=$TMPDIR
        export PIP_CACHE_DIR=$TMPDIR/pip-cache
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        
        # Set up venv in TMPDIR just to get pip
        python3.13 -m venv $TMPDIR/venv
        
        # Install directly to the target directory using the venv's pip
        $TMPDIR/venv/bin/pip install \
          --target $out/lib/google-colab-mcp \
          --no-cache-dir \
          --no-compile \
          google-colab-mcp==${version}

        # Clean up non-deterministic files
        find $out -name "direct_url.json" -delete
        find $out -name "*.pyc" -delete
        find $out -name "__pycache__" -type d -exec rm -rf {} +
      '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.python313}/bin/python3 $out/bin/colab-mcp \
        --add-flags "-c \"import sys; from mcp_colab_server import server_main; sys.exit(server_main())\"" \
        --set PYTHONPATH "$src/lib/google-colab-mcp"
    '';
  };

  makeSshMcp =
    {
      host,
      port ? 22,
      user,
      key ? "id_ed25519",
      homeDir,
    }:
    {
      command = "${ssh-mcp-pkg}/bin/ssh-mcp";
      args = [
        "--host=${host}"
        "--port=${toString port}"
        "--user=${user}"
        "--key=${homeDir}/.ssh/${key}"
        "--timeout=3000"
      ];
    };
in
selfLib.mkModule {
  name = "ai.mcp";
  description = "Nix-native Model Context Protocol (MCP) servers and configuration";

  hmConfig = hmOpts: {
    home = {
      packages = [
        ssh-mcp-pkg
        codebase-memory-mcp-pkg
        google-colab-mcp-pkg
        pkgs.github-mcp-server
        pkgs.mcp-server-memory
        inputs.mcp-nixos.packages.${system}.default
      ];

      activation.setupMcpConfig = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Path referensi
        TOKEN_PATH="${hmOpts.osConfig.sops.secrets."cloudflare-token".path}"
        BASE_CONF="$HOME/.gemini/config/mcp_config_base.json"
        FINAL_CONF="$HOME/.gemini/config/mcp_config.json"

        # Pastikan direktori tujuan ada
        mkdir -p "$HOME/.gemini/config"

        # Jika file token SOPS berhasil didekripsi, gabungkan konfigurasi
        if [ -f "$TOKEN_PATH" ]; then
          CF_TOKEN=$(cat "$TOKEN_PATH")
          
          # Gunakan jq untuk menambahkan server Cloudflare beserta Header Autentikasi
          ${pkgs.jq}/bin/jq --arg token "Bearer $CF_TOKEN" \
            '.mcpServers += {
              "cloudflare-api": {
                "url": "https://mcp.cloudflare.com/mcp",
                "headers": {
                  "Authorization": $token
                }
              }
            }' "$BASE_CONF" > "$FINAL_CONF"
             
          # Kunci izin file final agar hanya bisa dibaca oleh Anda
          chmod 600 "$FINAL_CONF"
        else
          # Jika token tidak ada, gunakan konfigurasi dasar saja
          cp "$BASE_CONF" "$FINAL_CONF"
          chmod 600 "$FINAL_CONF"
        fi
      '';
    };

    home.file.".gemini/config/mcp_config_base.json".text = builtins.toJSON {
      mcpServers = {
        ssh_openwrt_old = makeSshMcp {
          host = "192.168.5.1";
          user = "root";
          key = "id_rsa_compat";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        ssh_stb = makeSshMcp {
          host = "192.168.5.207";
          user = "klein";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        ssh_mido = makeSshMcp {
          host = "192.168.5.185";
          user = "klein";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        github = {
          command = "${pkgs.bash}/bin/bash";
          args = [
            "-c"
            "GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${
              hmOpts.osConfig.sops.secrets."github-access-token".path
            }) ${pkgs.github-mcp-server}/bin/github-mcp-server stdio"
          ];
        };

        memory = {
          command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
          args = [ ];
          env = {
            MEMORY_FILE_PATH = "${hmOpts.config.home.homeDirectory}/.gemini/memory.json";
          };
        };

        "codebase-memory-mcp" = {
          command = "${codebase-memory-mcp-pkg}/bin/codebase-memory-mcp";
          args = [ ];
          env = {
            CBM_CACHE_DIR = "${hmOpts.config.home.homeDirectory}/.agents/codebase_memory";
          };
        };

        nixos = {
          command = "${inputs.mcp-nixos.packages.${system}.default}/bin/mcp-nixos";
          args = [ ];
        };

        "google-colab-mcp" = {
          command = "${google-colab-mcp-pkg}/bin/colab-mcp";
          args = [ ];
        };
      };
    };
  };
}
