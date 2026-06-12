{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.apps.gaming.wine;
in
{
  options.my.user.apps.gaming.wine = {
    enable = lib.mkEnableOption "Wine settings";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Paket ini mendukung aplikasi 32-bit dan 64-bit
      wineWow64Packages.stable

      # Winetricks sangat berguna untuk menginstal dependencies tambahan (seperti .NET, DirectX)
      winetricks
      # bottles
    ];
    home.sessionVariables = {
      WINEDLLOVERRIDES = "winemenubuilder.exe=d";
      WINEPREFIX = "/mnt/data_btrfs/wine-data";
      WINEARCH = "win64";
    };
    home.file.".local/share/bottles".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/bottles";
  };
}
