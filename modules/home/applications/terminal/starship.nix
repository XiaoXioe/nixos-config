{
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.apps.terminal.starship;
in
{
  options.my.user.apps.terminal.starship = {
    enable = lib.mkEnableOption "Starship prompt configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        # Hilangkan baris kosong ekstra sebelum prompt agar lebih padat
        add_newline = false;

        # Format prompt satu baris: jam user@hostname ~ >>
        format = "$time $username@$hostname $directory$git_branch$git_status$container$nix_shell $character";

        # Modul Jam (Aktifkan dan atur formatnya)
        time = {
          disabled = false;
          time_format = "%H:%M:%S"; # Format jam 24-jam (misal: 18:58:34)
          format = "[$time]($style)";
          style = "bold cyan";
        };

        # Menampilkan Username secara permanen
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

        # Direktori tanpa warna mencolok
        directory = {
          style = "bold white";
          read_only = " ";
          truncation_length = 3;
          truncate_to_repo = false;
          format = "[$path]($style)";
        };

        # Karakter input yang diubah menjadi >>
        character = {
          success_symbol = "[>>](bold green)";
          error_symbol = "[>>](bold red)";
          vimcmd_symbol = "[<<](bold yellow)";
        };

        # Indikator Git tanpa kurung siku tebal
        git_branch = {
          symbol = " ";
          format = " [$symbol$branch]($style)";
          style = "italic purple";
        };
        git_status = {
          format = " ([$all_status$ahead_behind]($style))";
          style = "italic red";
        };

        # Indikator otomatis saat berada di dalam Distrobox
        container = {
          symbol = " ";
          format = " [$symbol$name]($style)";
          style = "dimmed yellow";
        };

        # Indikator saat masuk ke 'nix develop' atau 'nix shell'
        nix_shell = {
          symbol = " ";
          format = " [$symbol$state]($style)";
          style = "bold blue";
        };
      };
    };
  };
}
