{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.office.obsidian";
  description = "Obsidian Markdown note-taking and knowledge base application";

  flatpakCfg = {
    "md.obsidian.Obsidian" = {
      enable = true;
      symlinks = [
        {
          host = ".config/obsidian";
          guest = "config/obsidian";
        }
        {
          host = ".local/share/obsidian";
          guest = "data/obsidian";
        }
      ];
      nativePkgs = pkgs.obsidian;
    };
  };
}
