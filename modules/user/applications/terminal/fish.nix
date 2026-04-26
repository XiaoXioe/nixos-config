{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.fish;
in
{
  options.my.user.fish = {
    enable = selfLib.mkBoolOpt false "Fish shell configuration";
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

    programs.aichat = {
      enable = true;
      settings = {
        model = "gemini:gemini-2.5-flash";

        clients = [
          {
            type = "gemini";
          }
        ];
      };

      # Mendefinisikan agen khusus dengan kemampuan tingkat lanjut
      agents = {
        jarvis = {
          model = "gemini:gemini-2.5-flash";
          # fs = mengizinkan AI membaca file lokal
          # web_search = mengizinkan AI mencari data real-time di internet
          use_tools = "fs,web_search";
          description = "Asisten pintar yang bisa membaca file dan mencari internet.";
        };

        # Anda juga bisa membuat agen khusus untuk coding
        coder = {
          model = "gemini:gemini-2.5-flash";
          use_tools = "fs";
          description = "Ahli NixOS dan Python. Berikan jawaban dalam bentuk kode murni.";
        };
      };
    };

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_history_filter '^[ ]'
        set -p fish_function_path $HOME/.config/fish/functions/custom
        set -lx GEMINI_API_KEY (cat /run/secrets/gemini-api-key)

        # --- Fish Syntax Highlighting Colors (Pastel Theme) ---
        set -g fish_color_command cdd6f4       # Perintah (Putih Pastel)
        set -g fish_color_param 89b4fa         # Parameter (Biru Pastel)
        set -g fish_color_quote f9e2af         # Tanda Kutip (Kuning Pastel)
        set -g fish_color_error f38ba8         # Error (Merah Pastel)

        # Tambahan agar warna argumen lain ikut senada:
        set -g fish_color_escape f5c2e7        # Karakter escape (Pink Pastel)
        set -g fish_color_operator 94e2d5      # Operator seperti &, |, * (Cyan Pastel)
      '';
      # Memuat plugin-plugin terbaik untuk Fish
      plugins = with pkgs.fishPlugins; [
        {
          name = "pure";
          src = pure;
        }
      ];
      shellAliases = {

        # Mengganti perintah ls bawaan agar otomatis menggunakan eza
        ls = "eza --icons=auto";
        ll = "eza -lh --icons=auto --git"; # List memanjang, menampilkan ukuran file & status git
        la = "eza -lah --icons=auto --git"; # Sama seperti 'll', tapi menampilkan file tersembunyi

        cd = "z";

        # Keluar dari direktori dengan cepat
        ".." = "cd ..";
        "..." = "cd ../..";

        # Membersihkan layar
        c = "clear";

        # --- Monitoring & Analisis ---
        # io: Hanya tampilkan proses yang sedang R/W di disk
        io = "sudo iotop-c -oaP";
        sz = "sudo compsize -x";

        update = "sudo nixos-rebuild switch --flake ${config.my.user.flakePath}";
        cln = "nh clean all --keep 3 --ask --optimise";
        optimize = "nix-store --optimise";
        fadd = "git -C ${config.my.user.flakePath} add .";
        gcp = "git add . && git commit -m 'update' && git push";
        nfu = "nix flake update --flake ${config.my.user.flakePath}";

        #=========== Home manager ==========
        # 1. Kompilasi Standar (Sering Dipakai)
        hms = "nh home switch ${config.my.user.flakePath}";

        # 2. Kompilasi + Update Flake Inputs (Pembaruan Paket)
        hmu = "nh home switch -u ${config.my.user.flakePath}";

        # 3. Mode Simulasi / Uji Coba (Tanpa Menerapkan Perubahan)
        hmd = "nh home switch -n ${config.my.user.flakePath}";

        # 4. Mode "Penyelamat" (Mengatasi Konflik File)
        hmb = "nh home switch -b backup ${config.my.user.flakePath}";

        # 5. Mode Debugging (Melihat Log Lengkap jika Gagal)
        hmsv = "nh home switch --show-activation-logs ${config.my.user.flakePath}";

        # --- ALIAS NIXOS SYSTEM ---

        # 1. Kompilasi Sistem Standar (Rebuild & Switch)
        syu = "nh os switch ${config.my.user.flakePath}";

        # 2. Kompilasi Sistem + Update Flake Inputs (Pembaruan OS Penuh)
        syuu = "nh os switch -u ${config.my.user.flakePath}";

        # 3. Mode Simulasi / Uji Coba OS (Melihat daftar paket yang akan berubah tanpa menerapkan)
        syd = "nh os switch -n ${config.my.user.flakePath}";

        # 4. Mode Boot Saja (Rebuild, tapi tidak langsung diterapkan sekarang, hanya saat restart)
        syb = "nh os boot ${config.my.user.flakePath}";

        # 5. Mode Debugging OS (Tampilkan log lengkap jika kompilasi gagal)
        syv = "nh os switch --show-activation-logs ${config.my.user.flakePath}";

        # 6. Alias "Sapu Jagat" (Update dan Switch Sistem & Home Manager Sekaligus)
        upall = "nh os switch -u ${config.my.user.flakePath} && nh home switch -u ${config.my.user.flakePath}";

        squeeze = "sudo btrfs filesystem defragment -r -v -czstd";
        warp-on = "sudo bash ~/warp-configs/warp-bond.sh";
        warp-off = "sudo bash ~/warp-configs/wg-down.sh";
      };
    };
    xdg.configFile."fish/functions/custom".source =
      config.lib.file.mkOutOfStoreSymlink "${config.my.user.flakePath}/modules/user/conf/fish/functions";
  };
}
