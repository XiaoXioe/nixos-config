{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.zoxide";
  description = "Smarter cd command for shell navigation";

  hmConfig = {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
