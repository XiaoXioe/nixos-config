{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.security.compatibility;
in
{
  options.my.system.security.compatibility = {
    enable = lib.mkEnableOption "system binary compatibility (nix-ld)";
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      glib
      gtk3
      libusb1
    ];
  };
}
