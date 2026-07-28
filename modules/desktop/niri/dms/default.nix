{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri.dms";
  description = "DankMaterialShell";

  hmConfig =
    { inputs, ... }:
    {
      imports = [
        inputs.dms.homeModules.dank-material-shell
      ];

      programs.dank-material-shell = {
        enable = true;
        settings = import ./settings;
        clipboardSettings = {
          maxHistory = -1;
          maxEntrySize = 10485760;
          autoClearDays = 1;
          clearAtStartup = false;
          disabled = false;
          maxPinned = 25;
        };
      };
    };
}
