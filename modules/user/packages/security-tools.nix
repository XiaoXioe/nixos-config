{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.security-tools;
in
{
  options.my.user.security-tools = {
    enable = selfLib.mkBoolOpt false "cybersecurity and penetration testing tools for home manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dig
      pkgsUnstable.sqlmap
      binwalk
      file
      tor-browser
      protonvpn-gui
      dalfox
      keepassxc
      mubeng
      pkgsUnstable.sherlock
    ];
  };
}
