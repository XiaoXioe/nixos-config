{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.zoxide";
  description = "Smarter cd command for shell navigation";

  hmConfig = hmOpts: {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
