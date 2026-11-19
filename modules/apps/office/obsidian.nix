{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.office.obsidian";
  description = "Obsidian Markdown note-taking and knowledge base application";

  hmConfig = {
    home.packages = [ pkgs.obsidian ];
  };
}
