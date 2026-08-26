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

  cachePinTools = pkgs.stdenv.mkDerivation {
    pname = "nix-cache-pin-tools";
    version = "2.0.0";
    src = ./scripts;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/nix-cache-pin-tools $out/bin
      cp -r * $out/lib/nix-cache-pin-tools/

      # Unified entry point: nix-cache-pin (ncp)
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/nix-cache-pin \
        --add-flags "$out/lib/nix-cache-pin-tools/cli/main.py" \
        --prefix PYTHONPATH : "$out/lib/nix-cache-pin-tools" \
        --prefix PATH : ${runtimeDeps}

      # Short alias
      ln -s $out/bin/nix-cache-pin $out/bin/ncp
    '';
  };

  fishCompletions = ''
    function __fish_cache_pin_keys
        set -l pins_file "$HOME/nixos-config/modules/_lib/cache-pins.nix"
        if test -f "$pins_file"
            grep -E '^[ ]{2}[a-zA-Z0-9_-]+[ ]*=[ ]*\{' "$pins_file" | sed -E 's/^[ ]*([a-zA-Z0-9_-]+).*/\1/'
        end
    end

    # ncp subcommand completions
    complete -c ncp -n __fish_use_subcommand -a "query" -d "Cek status cache, closure, narinfo"
    complete -c ncp -n __fish_use_subcommand -a "fetch" -d "Download NAR closure via aria2c"
    complete -c ncp -n __fish_use_subcommand -a "update" -d "Update pin dari upstream"
    complete -c ncp -n __fish_use_subcommand -a "audit" -d "Audit pin unused/orphan"
    complete -c ncp -n __fish_use_subcommand -a "adopt" -d "Adopsi paket ke cache-pin"
    complete -c ncp -n __fish_use_subcommand -a "diff" -d "Bandingkan closure pin lokal vs upstream"
    complete -c ncp -n __fish_use_subcommand -a "tree" -d "Visualisasi grafik dependensi via nix-tree"
    complete -c ncp -n __fish_use_subcommand -a "tui" -d "FZF Dashboard interaktif"
    complete -c ncp -n __fish_use_subcommand -a "stats" -d "Dashboard statistik"
    complete -c ncp -n __fish_use_subcommand -a "delete" -d "Hapus pin dari registry"
    complete -c ncp -n __fish_use_subcommand -a "search" -d "Cari versi paket via FZF"

    # Global options
    complete -c ncp -s c -l channel -x -a "unstable nixpkgs-unstable 26.05 25.11 25.05 24.11 24.05 master" -d "Shorthand channel Nixpkgs"
    complete -c ncp -l cache-url -d "Binary cache URL"
    complete -c ncp -l input -d "Flake input target"
    complete -c ncp -l pins-file -r -d "Path ke berkas cache-pins.nix"

    # ncp query
    complete -c ncp -n "__fish_seen_subcommand_from query q" -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"
    complete -c ncp -n "__fish_seen_subcommand_from query q" -s v -l verbose -d "Tampilkan seluruh daftar dependensi"
    complete -c ncp -n "__fish_seen_subcommand_from query q" -s w -l write -d "Tulis/perbarui entri di cache-pins.nix"
    complete -c ncp -n "__fish_seen_subcommand_from query q" -l all -d "Verifikasi seluruh entri"

    # ncp fetch
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l all-active -d "Unduh massal pin aktif"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l all-pins -d "Unduh massal seluruh pin"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l keep-nar -d "Pertahankan .nar di RAM setelah ingest"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l split -d "Koneksi paralel per file (default: 8)"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -s j -l concurrent -d "Download bersamaan (default: 4)"
    complete -c ncp -n "__fish_seen_subcommand_from fetch f" -l cache-dir -r -d "Direktori cache lokal"

    # ncp update
    complete -c ncp -n "__fish_seen_subcommand_from update u" -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l all -d "Perbarui seluruh pin"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -s w -l write -d "Simpan perubahan ke file"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -s f -l force -d "Izinkan downgrade"
    complete -c ncp -n "__fish_seen_subcommand_from update u" -l version-only -d "Hanya update jika versi naik"

    # ncp audit
    complete -c ncp -n "__fish_seen_subcommand_from audit a" -l clean -d "Hapus pin yatim"
    complete -c ncp -n "__fish_seen_subcommand_from audit a" -s f -l force -d "Lewati konfirmasi"

    # ncp adopt
    complete -c ncp -n "__fish_seen_subcommand_from adopt" -a "(__fish_cache_pin_keys)" -d "Paket target"

    # ncp diff
    complete -c ncp -n "__fish_seen_subcommand_from diff d" -a "(__fish_cache_pin_keys)" -d "Paket target"
    complete -c ncp -n "__fish_seen_subcommand_from diff d" -l deep -d "Gunakan nix-diff untuk analisis semantik mendalam"

    # ncp tree
    complete -c ncp -n "__fish_seen_subcommand_from tree t" -a "(__fish_cache_pin_keys)" -d "Paket target"

    # ncp delete
    complete -c ncp -n "__fish_seen_subcommand_from delete rm del" -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"

    # ncp search
    complete -c ncp -n "__fish_seen_subcommand_from search s" -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"

    # nix-cache-pin wraps ncp
    complete -c nix-cache-pin -w ncp
  '';

  bashCompletions = ''
    _ncp_complete() {
        local cur prev words cword
        _init_completion || return

        local pins_file="$HOME/nixos-config/modules/_lib/cache-pins.nix"
        local keys=""
        if [[ -f "$pins_file" ]]; then
            keys=$(grep -E '^[ ]{2}[a-zA-Z0-9_-]+[ ]*=[ ]*\{' "$pins_file" | sed -E 's/^[ ]*([a-zA-Z0-9_-]+).*/\1/')
        fi

        local subcommands="query fetch update audit adopt diff tree tui stats delete search"

        if [[ $cword -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "$subcommands --help --version" -- "$cur") )
            return 0
        fi

        local subcmd="''${words[1]}"

        case "$subcmd" in
            query|q)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "-v --verbose -w --write --all -c --channel --cache-url --input --pins-file" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                fi
                ;;
            fetch|f)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--all-active --all-pins --keep-nar --split -j --concurrent --cache-dir -c --channel --cache-url --input --pins-file" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                fi
                ;;
            update|u)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--all -w --write -f --force --version-only --bump-only -c --channel --cache-url --input --pins-file" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                fi
                ;;
            audit|a)
                COMPREPLY=( $(compgen -W "--clean -f --force --pins-file" -- "$cur") )
                ;;
            adopt)
                COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                ;;
            diff|d)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--deep -c --channel --input --pins-file" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                fi
                ;;
            tree|t)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "-c --channel --input --pins-file" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                fi
                ;;
            delete|rm|del)
                COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                ;;
            search|s)
                COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
                ;;
        esac
    }
    complete -F _ncp_complete ncp nix-cache-pin
  '';
in
selfLib.mkModule {
  name = "apps.dev.nix.cache-pins";
  description = "Unified Nix Binary Cache pin management CLI (nix-cache-pin / ncp): query, fetch, update, audit, adopt, diff, tree, and TUI dashboard";

  hmConfig = {
    home.packages = [
      cachePinTools
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
