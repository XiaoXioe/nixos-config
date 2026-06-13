{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.starship";
  description = "Starship prompt configuration";

  hmConfig = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        add_newline = false;
        format = "$time $username@$hostname $directory$git_branch$git_status$container$nix_shell $character";
        time = {
          disabled = false;
          time_format = "%H:%M:%S";
          format = "[$time]($style)";
          style = "bold cyan";
        };
        username = {
          show_always = true;
          format = "[$user]($style)";
          style_user = "bold blue";
          style_root = "bold red";
        };
        hostname = {
          ssh_only = false;
          format = "[$hostname]($style)";
          style_bold_blue = "bold blue";
        };
        directory = {
          style = "bold white";
          read_only = " ";
          truncation_length = 3;
          truncate_to_repo = false;
          format = "[$path]($style)";
        };
        character = {
          success_symbol = "[>>](bold green)";
          error_symbol = "[>>](bold red)";
          vimcmd_symbol = "[<<](bold yellow)";
        };
        git_branch = {
          symbol = " ";
          format = " [$symbol$branch]($style)";
          style = "italic purple";
        };
        git_status = {
          format = " ([$all_status$ahead_behind]($style))";
          style = "italic red";
        };
        container = {
          symbol = " ";
          format = " [$symbol$name]($style)";
          style = "dimmed yellow";
        };
        nix_shell = {
          symbol = " ";
          format = " [$symbol$state]($style)";
          style = "bold blue";
        };
      };
    };
  };
}
