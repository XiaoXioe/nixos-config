{
  config,
  lib,
  pkgs,
  flakePath,
  ...
}:

let
  cfg = config.my.user.fish;
in
{
  options.my.user.fish = {
    enable = lib.mkEnableOption "Fish shell configuration";
  };

  config = lib.mkIf cfg.enable {
    # --- FZF: Fuzzy Finder ---
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;

      # Warna highlight akan otomatis disuntikkan ke terminal
      colors = {
        "bg+" = "#3b4252";
        "fg+" = "#e5e9f0";
        "hl+" = "#81a1c1";
        "pointer" = "#b48ead";
        "marker" = "#a3be8c";
      };

      # Mengaktifkan preview box
      defaultOptions = [
        "--preview 'echo {}'"
        "--preview-window down:3:wrap"
      ];
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # --- Zoxide: Pengganti 'cd' yang cerdas ---
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    # --- Eza: Pengganti 'ls' modern ---
    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto"; # Mengaktifkan ikon
      git = true; # Mengaktifkan integrasi Git
    };

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
        set -g fish_history_filter '^[ ]'
        set -p fish_function_path $HOME/.config/fish/functions/custom
        # set -lx GEMINI_API_KEY (cat /run/secrets/gemini-api-key)

        set -g fish_color_command cdd6f4       # Perintah (Putih Pastel)
        set -g fish_color_param 89b4fa         # Parameter (Biru Pastel)
        set -g fish_color_quote f9e2af         # Tanda Kutip (Kuning Pastel)
        set -g fish_color_error f38ba8         # Error (Merah Pastel)

        set -g fish_color_escape f5c2e7        # Karakter escape (Pink Pastel)
        set -g fish_color_operator 94e2d5      # Operator seperti &, |, * (Cyan Pastel)
      '';

      # Memuat plugin-plugin terbaik untuk Fish
      plugins = with pkgs.fishPlugins; [
        {
          name = "async-prompt";
          src = async-prompt;
        }
        {
          name = "autopair";
          src = autopair;
        }
      ];

      shellAbbrs = {
        gl = "gallery-dl";
        aria = "aria2c -x16 -s16 -c '' -o ''";
      };
      shellAliases = {

        # Mengganti perintah ls bawaan agar otomatis menggunakan eza
        ls = "eza --icons=auto";
        ll = "eza -lh --icons=auto --git"; # List memanjang, menampilkan ukuran file & status git
        la = "eza -lah --icons=auto --git"; # Sama seperti 'll', tapi menampilkan file tersembunyi

        cd = "z";
        editnix = "codium ~/nixos-config";

        # Keluar dari direktori dengan cepat
        ".." = "cd ..";
        "..." = "cd ../..";

        # Membersihkan layar
        c = "clear";

        # --- Monitoring & Analisis ---
        sz = "sudo compsize -x";

        rebuild = "sudo nixos-rebuild switch --flake ${config.my.user.flakePath} --print-build-logs --show-trace";
        cln = "nh clean all --keep 3 --ask --optimise";
        gcp = "git add . && git commit -m 'update' && git push";
        nfu = "nix flake update --flake ${config.my.user.flakePath}";

        # --- ALIAS NIXOS SYSTEM ---
        rbs = "nh os switch ${config.my.user.flakePath}";
        ostest = "nh os test ${config.my.user.flakePath}";
        osboot = "nh os boot ${config.my.user.flakePath}";

        squeeze = "sudo btrfs filesystem defragment -r -v -czstd";
      };
    };
    xdg.configFile."fish/functions/custom".source =
      config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/home/conf/fish/functions";
  };
}
