{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.social.ayugram";
  description = "AyuGram Desktop Messaging application";

  flatpakCfg = {
    "com.ayugram.desktop" = {
      enable = true;
      sha256 = "0jk3f1dsb2jb77rk1a8rm5jnh6315mhxf1fnm70vgwmn1a2xd6rp";
      bundle = "${pkgs.fetchurl {
        url = "https://github.com/0FL01/AyuGramDesktop-flatpak/releases/download/flatpak-v6.7.8-20260604235309/ayugram-desktop-6.7.8.flatpak";
        sha256 = "0jk3f1dsb2jb77rk1a8rm5jnh6315mhxf1fnm70vgwmn1a2xd6rp";
      }}";
      symlinks = [
        {
          host = ".local/share/AyuGramDesktop";
          guest = "data/AyuGramDesktop";
        }
      ];
      nativePkgs = pkgs.ayugram-desktop;
    };
  };
}
