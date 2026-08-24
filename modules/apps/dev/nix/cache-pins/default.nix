{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pythonEnv = pkgs.python3;

  cachePinTools = pkgs.stdenv.mkDerivation {
    pname = "nix-cache-pin-tools";
    version = "1.0.0";
    src = ./scripts;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/nix-cache-pin-tools $out/bin
      cp -r * $out/lib/nix-cache-pin-tools/

      # query-cache-pin
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/query-cache-pin \
        --add-flags "$out/lib/nix-cache-pin-tools/query_pin.py" \
        --prefix PYTHONPATH : "$out/lib/nix-cache-pin-tools" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.nix
            pkgs.curl
            pkgs.fzf
            pkgs.nixfmt
            pkgs.coreutils
          ]
        }

      # aria2-fetch-pin
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/aria2-fetch-pin \
        --add-flags "$out/lib/nix-cache-pin-tools/aria2_fetch.py" \
        --prefix PYTHONPATH : "$out/lib/nix-cache-pin-tools" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.nix
            pkgs.aria2
            pkgs.fzf
            pkgs.nixfmt
            pkgs.coreutils
          ]
        }

      # Aliases
      ln -s $out/bin/query-cache-pin $out/bin/qcp
      ln -s $out/bin/aria2-fetch-pin $out/bin/afp
    '';
  };

  fishCompletions = ''
    function __fish_cache_pin_keys
        set -l pins_file "$HOME/nixos-config/modules/_lib/cache-pins.nix"
        if test -f "$pins_file"
            grep -E '^[ ]{2}[a-zA-Z0-9_-]+[ ]*=[ ]*\{' "$pins_file" | sed -E 's/^[ ]*([a-zA-Z0-9_-]+).*/\1/'
        end
    end

    # query-cache-pin / qcp completions
    complete -c query-cache-pin -s c -l channel -x -a "unstable nixpkgs-unstable 26.05 25.11 25.05 24.11 24.05 master" -d "Shorthand channel Nixpkgs"
    complete -c query-cache-pin -s v -l verbose -d "Tampilkan seluruh daftar dependensi"
    complete -c query-cache-pin -s w -l write -d "Tulis/perbarui entri di cache-pins.nix"
    complete -c query-cache-pin -s i -l interactive -d "Buka TUI Dashboard interaktif fzf"
    complete -c query-cache-pin -s s -l search-versions -d "Cari versi lain dari paket via FZF"
    complete -c query-cache-pin -l all -d "Verifikasi seluruh entri di cache-pins.nix"
    complete -c query-cache-pin -l audit-unused -d "Audit penggunaan pin di codebase modules (deteksi dangling pins)"
    complete -c query-cache-pin -l clean-unused -d "Hapus seluruh pin yang tidak lagi terpakai dari cache-pins.nix"
    complete -c query-cache-pin -l adopt -d "Adopsi paket dari pkgs ke cache pin dan otomatis refactor modul target"
    complete -c query-cache-pin -l stats -l summary -d "Tampilkan dashboard statistik dan kesiapan /nix/store"
    complete -c query-cache-pin -l prefetch -d "Unduh massal seluruh pin aktif ke /nix/store via aria2c"
    complete -c query-cache-pin -s d -l delete -x -a "(__fish_cache_pin_keys)" -d "Hapus entri paket dari cache-pins.nix"
    complete -c query-cache-pin -s f -l force -d "Lewati konfirmasi saat membersihkan pin"
    complete -c query-cache-pin -l update -x -a "(__fish_cache_pin_keys)" -d "Perbarui paket tertentu dari upstream"
    complete -c query-cache-pin -l update-all -d "Perbarui seluruh entri cache-pins.nix dari upstream"
    complete -c query-cache-pin -l version-only -l bump-only -d "Hanya perbarui jika versi naik (abaikan rebuild berversi sama)"
    complete -c query-cache-pin -l cache-url -d "Binary cache URL (multi-cache dipisahkan koma)"
    complete -c query-cache-pin -l input -d "Flake input target"
    complete -c query-cache-pin -l pins-file -r -d "Path ke berkas cache-pins.nix"
    complete -c query-cache-pin -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"

    complete -c qcp -w query-cache-pin

    # aria2-fetch-pin / afp completions
    complete -c aria2-fetch-pin -s c -l channel -x -a "unstable nixpkgs-unstable 26.05 25.11 25.05 24.11 24.05 master" -d "Shorthand channel Nixpkgs"
    complete -c aria2-fetch-pin -l all-active -d "Unduh secara massal seluruh pin aktif ke /nix/store"
    complete -c aria2-fetch-pin -l all-pins -d "Unduh secara massal seluruh pin terdaftar ke /nix/store"
    complete -c aria2-fetch-pin -s i -l interactive -d "Buka TUI Dashboard interaktif fzf"
    complete -c aria2-fetch-pin -s s -l search-versions -d "Cari versi lain dari paket via FZF sebelum mengunduh"
    complete -c aria2-fetch-pin -l keep-nar -d "Pertahankan arsip .nar di RAM setelah ingest selesai"
    complete -c aria2-fetch-pin -l split -d "Koneksi paralel per file (default: 8)"
    complete -c aria2-fetch-pin -s j -l concurrent -d "Maksimum download bersamaan (default: 4)"
    complete -c aria2-fetch-pin -l cache-url -d "Binary cache URL"
    complete -c aria2-fetch-pin -l input -d "Flake input target"
    complete -c aria2-fetch-pin -l cache-dir -r -d "Direktori cache lokal aria2 (default: RAM tmpfs)"
    complete -c aria2-fetch-pin -l pins-file -r -d "Path ke berkas cache-pins.nix"
    complete -c aria2-fetch-pin -a "(__fish_cache_pin_keys)" -d "Paket cache-pin"

    complete -c afp -w aria2-fetch-pin
  '';

  bashCompletions = ''
    _cache_pins_complete() {
        local cur prev words cword
        _init_completion || return

        local pins_file="$HOME/nixos-config/modules/_lib/cache-pins.nix"
        local keys=""
        if [[ -f "$pins_file" ]]; then
            keys=$(grep -E '^[ ]{2}[a-zA-Z0-9_-]+[ ]*=[ ]*\{' "$pins_file" | sed -E 's/^[ ]*([a-zA-Z0-9_-]+).*/\1/')
        fi

        if [[ "$prev" == "-c" || "$prev" == "--channel" ]]; then
            COMPREPLY=( $(compgen -W "unstable nixpkgs-unstable 26.05 25.11 25.05 24.11 24.05 master" -- "$cur") )
            return 0
        fi

        if [[ "$prev" == "-d" || "$prev" == "--delete" || "$prev" == "--update" ]]; then
            COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
            return 0
        fi

        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "-c --channel -v --verbose -w --write -d --delete -f --force --adopt --stats --summary --prefetch -i --interactive -s --search-versions --keep-nar --all --all-active --all-pins --audit-unused --clean-unused --update --update-all --version-only --bump-only --cache-url --input --pins-file --split -j --concurrent --cache-dir" -- "$cur") )
            return 0
        fi

        COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
    }
    complete -F _cache_pins_complete query-cache-pin qcp aria2-fetch-pin afp
  '';
in
selfLib.mkModule {
  name = "apps.dev.nix.cache-pins";
  description = "Modular Nix Binary Cache auditing (query-cache-pin / qcp) and multi-connection aria2 closure downloader (aria2-fetch-pin / afp)";

  hmConfig = {
    home.packages = [
      cachePinTools
    ];

    xdg.configFile =
      (selfLib.mkShellCompletions pkgs {
        name = "cache-pins";
        fish = fishCompletions;
        bash = bashCompletions;
      })
      // {
        "fish/completions/query-cache-pin.fish".text = fishCompletions;
        "fish/completions/qcp.fish".text = fishCompletions;
        "fish/completions/aria2-fetch-pin.fish".text = fishCompletions;
        "fish/completions/afp.fish".text = fishCompletions;
      };
  };
}
