{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.eza";
  description = "Modern replacement for ls with icons and git integration";

  hmConfig = {
    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto";
      git = true;
    };
  };
}
