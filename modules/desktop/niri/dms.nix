{
  pkgs,
  inputs,
  config,
  osConfig,
  ...
}:
{
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    dgop.package = pkgs.dgop;
    enable = true;
  };

  # Link DankMaterialShell configuration from the repository using out-of-store symlink
  xdg.configFile."DankMaterialShell".source =
    config.lib.file.mkOutOfStoreSymlink "${osConfig.my.user.flakePath}/modules/dotfiles/DankMaterialShell";
}
