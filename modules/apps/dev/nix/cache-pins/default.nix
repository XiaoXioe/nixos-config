{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.urllib3 ]);

  runtimeDeps = lib.makeBinPath [
    pkgs.nix
    pkgs.aria2
    pkgs.curl
    pkgs.fzf
    pkgs.git
    pkgs.nixfmt
    pkgs.coreutils
    pkgs.nix-tree
    pkgs.nvd
    pkgs.nix-diff
    pkgs.nurl
  ];

  cacheIngestTools = pkgs.stdenv.mkDerivation {
    pname = "nix-cache-ingest-tools";
    version = "4.0.0";
    src = ./scripts;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/nix-cache-ingest-tools $out/bin
      cp -r * $out/lib/nix-cache-ingest-tools/

      # Unified entry point: nix-cache-pin / ncp
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/nix-cache-pin \
        --add-flags "$out/lib/nix-cache-ingest-tools/cli/main.py" \
        --prefix PYTHONPATH : "$out/lib/nix-cache-ingest-tools" \
        --prefix PATH : ${runtimeDeps}

      # Short alias
      ln -s $out/bin/nix-cache-pin $out/bin/ncp
    '';
  };

  fishCompletions = ''
    # ncp subcommand completions
    complete -c ncp -n __fish_use_subcommand -a "fetch" -d "Download NAR/FOD closure via aria2c & reactive ingest"
    complete -c ncp -n __fish_use_subcommand -a "update" -d "Update flake.lock & unduh closure sistem via aria2c"
    complete -c ncp -n __fish_use_subcommand -a "query" -d "Cek status cache, closure, dan narinfo paket"
    complete -c ncp -n __fish_use_subcommand -a "tree" -d "Visualisasi grafik dependensi via nix-tree"
    complete -c ncp -n __fish_use_subcommand -a "search" -d "Cari versi paket lintas channel via FZF"

    # Global options
    complete -c ncp -s c -l channel -x -a "unstable nixpkgs-unstable 26.05 25.11 25.05 24.11 master" -d "Shorthand channel Nixpkgs"
    complete -c ncp -l cache-url -d "Binary cache URL"
    complete -c ncp -l input -d "Flake input target"
    complete -c ncp -l refresh -l no-cache -d "Abaikan disk cache evaluasi lokal"
    complete -c ncp -s j -l concurrency -d "Tingkat paralelisme worker/koneksi (default: 16)"
    complete -c ncp -s v -l verbose -d "Tampilkan log stream evaluasi Nix lengkap"

    # ncp fetch
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -a "system" -d "Unduh seluruh closure sistem NixOS"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l system -d "Unduh seluruh biner closure sistem NixOS"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l host -d "Hostname target konfigurasi NixOS"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l dry-run -d "Hanya tampilkan biner sistem tanpa mengunduh"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l keep-nar -d "Pertahankan .nar di RAM setelah ingest"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l split -d "Koneksi paralel per file (default: 8)"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -s j -l concurrent -d "Download bersamaan (default: 4)"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l cache-dir -r -d "Direktori cache lokal"

    # ncp update
    complete -c ncp -n "__fish_seen_subcommand_from update u" -a "system nixpkgs nixpkgs-unstable nix-cachyos-kernel" -d "Target flake input atau sistem"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l system -d "Perbarui flake.lock dan unduh closure sistem via aria2c"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -s i -l flake-input -d "Flake input spesifik yang akan di-update"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l host -d "Hostname target konfigurasi NixOS"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l dry-run -d "Hanya evaluasi tanpa mengunduh"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l keep-nar -d "Pertahankan .nar di RAM setelah ingest"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l split -d "Koneksi paralel per file (default: 8)"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -s j -l concurrent -d "Download bersamaan (default: 4)"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l cache-dir -r -d "Direktori cache lokal"

    # ncp query
    complete -c ncp -n "__fish_seen_subcommand_from query q" -s v -l verbose -d "Tampilkan seluruh daftar dependensi"

    # nix-cache-pin wraps ncp
    complete -c nix-cache-pin -w ncp
  '';

  bashCompletions = ''
    _ncp_complete() {
        local cur prev words cword
        _init_completion || return

        local subcommands="fetch update query tree search"

        if [[ $cword -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "$subcommands --help --version --refresh --no-cache -j --concurrency -v --verbose" -- "$cur") )
            return 0
        fi

        local subcmd="''${words[1]}"

        case "$subcmd" in
            fetch|f)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--system --host --dry-run --keep-nar --split -j --concurrent --cache-dir -c --channel --cache-url --input" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "system" -- "$cur") )
                fi
                ;;
            update|u)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--system -i --flake-input --host --dry-run --keep-nar --split -j --concurrent --cache-dir --cache-url" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "system nixpkgs nixpkgs-unstable nix-cachyos-kernel" -- "$cur") )
                fi
                ;;
            query|q)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "-v --verbose -c --channel --cache-url --input --refresh --no-cache -j --concurrency" -- "$cur") )
                fi
                ;;
            tree|t)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "-c --channel --input" -- "$cur") )
                fi
                ;;
        esac
    }
    complete -F _ncp_complete ncp nix-cache-pin
  '';
in
selfLib.mkModule {
  name = "apps.dev.nix.cache-pins";
  description = "High-performance Nix Binary Cache downloader and reactive ingest CLI (ncp): fetch, update, query, tree, search";

  preservation = {
    userDirectories = [
      ".cache/ncp"
    ];
  };

  hmConfig = {
    home.packages = [
      cacheIngestTools
      pkgs.nix-tree
      pkgs.nvd
      pkgs.nix-diff
      pkgs.nurl
    ];

    xdg.configFile =
      (selfLib.mkShellCompletions pkgs {
        name = "cache-pins";
        fish = fishCompletions;
        bash = bashCompletions;
      })
      // {
        "fish/completions/ncp.fish".text = fishCompletions;
        "fish/completions/nix-cache-pin.fish".text = fishCompletions;
      };
  };
}
