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

        # Format prompt dua baris:
        # Baris 1: [Container/Nix] [Direktori] [Git]
        # Baris 2: ❯
        format = ''
          $container$nix_shell$directory$git_branch$git_status
          $character
        '';

        # Karakter input minimalis
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vimcmd_symbol = "[❮](bold yellow)";
        };

        # Indikator direktori yang bersih
        directory = {
          style = "bold cyan";
          read_only = " ";
          truncation_length = 3;
          truncate_to_repo = false;
        };

        # Indikator Git yang tidak berisik
        git_branch = {
          symbol = " ";
          style = "italic purple";
        };
        git_status = {
          style = "italic red";
        };

        # Indikator otomatis saat Anda berada di dalam Distrobox!
        container = {
          symbol = " ";
          format = "[$symbol$name]($style) ";
          style = "dimmed yellow";
        };

        # Indikator saat Anda masuk ke 'nix develop' atau 'nix shell'
        nix_shell = {
          symbol = " ";
          format = "[$symbol$state]($style) ";
          style = "bold blue";
        };
      };
    };
  };
}
