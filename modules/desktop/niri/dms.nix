{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri.dms";
  description = "DankMaterialShell";

  nixosConfig = {
    programs.dms-shell = {
      enable = true;
      systemd = {
        enable = false;
      };
    };
  };

  hmConfig = hmOpts: {
    # Link DankMaterialShell configuration from the repository using out-of-store symlink
    xdg.configFile."DankMaterialShell".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "${config.my.user.flakePath}/dotfiles/DankMaterialShell";
  };
}
