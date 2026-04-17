{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.distrobox;
in
{
  options.my.user.distrobox = {
    enable = selfLib.mkBoolOpt false "Distrobox configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      boxbuddy
      distrobox
    ];

    home.file.".config/distrobox/distrobox.ini".source =
      config.lib.file.mkOutOfStoreSymlink "${config.my.user.flakePath}/modules/user/conf/distrobox/distrobox.ini";

    programs.distrobox = {
      containers = {
        arch-linux = {
          additional_packages = "git base-devel vim fastfetch";
          entry = true;
          image = "archlinux:latest";
        };
      };
    };
  };
}
