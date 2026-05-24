{
  config,
  lib,
  inputs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.nvim;
in
{
  options.my.user.nvim = {
    enable = selfLib.mkBoolOpt false "Neovim configuration";
  };

  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
    programs.nvf = {
      enable = true;

      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;

          # Tampilan & Tema
          theme = {
            enable = true;
            name = "gruvbox";
            style = "dark";
          };

          # Plugin Antarmuka Dasar
          statusline.lualine.enable = true;
          telescope.enable = true; # Pencarian file yang sangat berguna
          autocomplete.nvim-cmp.enable = true;

          lsp = {
            enable = true;
          };

          # Bahasa & Sintaksis Dasar
          languages = {
            enableTreesitter = true;
            enableFormat = true; # Mengaktifkan format-on-save secara global (jika didukung)

            # Pengaturan Nix
            nix = {
              enable = true;
              format = {
                enable = true;
                type = [ "nixfmt" ];
              };
            };

            # Pengaturan Python
            python = {
              enable = true;
              format = {
                enable = true;
                type = [ "black" ];
              };
            };

            # Pengaturan YAML (Sangat berguna untuk file secrets.yaml di sops-nix)
            yaml = {
              enable = true;
            };

            bash.enable = true;
          };
        };
      };
    };
  };
}
