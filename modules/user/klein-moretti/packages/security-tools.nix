{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.security-tools;
in
{
  options.my.user.security-tools = {
    enable = lib.mkEnableOption "cybersecurity and penetration testing tools for home manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dig
      sqlmap
      binwalk
      file
      tor-browser
      proton-vpn
      dalfox      keepassxc
      mubeng
      sherlock
      exiftool
    ];
  };
}
