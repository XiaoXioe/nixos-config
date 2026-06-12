{
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.editors.neovim";
  description = "Neovim configuration";

  nixosConfig = {
    # NixOS side (optional, e.g. packages)
  };

  hmConfig = {
    imports = [ inputs.nvf.homeManagerModules.default ];
    programs.nvf = {
      enable = true;
      settings.vim = {
        viAlias = true;
        vimAlias = true;
        theme = { enable = true; name = "gruvbox"; style = "dark"; };
        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;
        lsp.enable = true;
        languages = {
          enableTreesitter = true;
          enableFormat = true;
          nix = { enable = true; format = { enable = true; type = [ "nixfmt" ]; }; };
          python = { enable = true; format = { enable = true; type = [ "black" ]; }; };
          yaml.enable = true;
          bash.enable = true;
        };
      };
    };
  };
}
