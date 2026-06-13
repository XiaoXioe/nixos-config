{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.compat";
  nixosConfig = {
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
