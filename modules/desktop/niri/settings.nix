{ config, osConfig, ... }:
{
  # Link niri configuration from the repository using out-of-store symlink
  xdg.configFile."niri".source = config.lib.file.mkOutOfStoreSymlink "${osConfig.my.user.flakePath}/dotfiles/niri";
}
