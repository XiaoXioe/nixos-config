{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.wine";
  description = "Wine settings";

  hmConfig = {
    home.packages = with pkgs; [ wineWow64Packages.stable winetricks ];
    home.sessionVariables = { WINEDLLOVERRIDES = "winemenubuilder.exe=d"; WINEPREFIX = "/mnt/data_btrfs/wine-data"; WINEARCH = "win64"; };
    home.file.".local/share/bottles".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/bottles";
  };
}
