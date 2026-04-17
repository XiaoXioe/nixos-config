{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.wine;
in
{
  options.my.user.wine = {
    enable = selfLib.mkBoolOpt false "Wine settings";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Paket ini mendukung aplikasi 32-bit dan 64-bit
      wineWow64Packages.stable

      # Winetricks sangat berguna untuk menginstal dependencies tambahan (seperti .NET, DirectX)
      winetricks
      bottles
    ];
    home.sessionVariables = {
      WINEPREFIX = "/mnt/data_btrfs/wine-data";
    };
    home.file.".local/share/bottles".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/bottles";
  };
}
