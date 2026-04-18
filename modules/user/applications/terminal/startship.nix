{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.user.startship;
in
{
  options.my.user.startship = {
    enable = selfLib.mkBoolOpt false "Startship configuration for fishshell";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        # Hilangkan baris kosong ekstra sebelum prompt agar lebih padat
        add_newline = false;

        # Format prompt dua baris ala Kali Linux:
        # Ditambahkan spasi agar tidak terlalu rapat, dan karakter ㉿ dikembalikan.
        # Baris 1: ┌──(user㉿host)-[~/dir]
        # Baris 2: └─#
        format = ''
          [┌──\(](bold blue)$username[㉿](bold white)$hostname[\)](bold blue)$directory$git_branch$git_status$container$nix_shell
          [└─](bold blue)$character
        '';

        # Menampilkan Username secara permanen (berwarna biru, merah jika root)
        username = {
          show_always = true;
          format = "[$user]($style)";
          style_user = "bold blue";
          style_root = "bold red";
        };

        # Menampilkan Hostname secara permanen
        hostname = {
          ssh_only = false;
          format = "[$hostname]($style)";
          style = "bold blue";
        };

        # Direktori tanpa warna mencolok, dibungkus kurung siku oleh format utama
        directory = {
          style = "bold white";
          read_only = " ";
          truncation_length = 3;
          truncate_to_repo = false;
          format = "[$path]($style)";
        };

        # Karakter input yang sudah Anda sesuaikan
        character = {
          success_symbol = "(bold white)[#](bold blue)";
          error_symbol = "(bold white)[#](bold red)";
          vimcmd_symbol = "[❮](bold yellow)";
        };

        # Indikator Git dibungkus kurung siku agar senada dengan alur Kali
        git_branch = {
          symbol = " ";
          format = "-\\[[$symbol$branch]($style)\\]";
          style = "italic purple";
        };
        git_status = {
          format = "([$all_status$ahead_behind]($style))";
          style = "italic red";
        };

        # Indikator otomatis saat Anda berada di dalam Distrobox
        container = {
          symbol = " ";
          format = "-\\[[$symbol$name]($style)\\]";
          style = "dimmed yellow";
        };

        # Indikator saat Anda masuk ke 'nix develop' atau 'nix shell'
        nix_shell = {
          symbol = " ";
          format = "-\\[[$symbol$state]($style)\\]";
          style = "bold blue";
        };
      };
    };
  };
}
