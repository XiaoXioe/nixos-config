{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.tools";
  description = "Modern command-line utilities and tools for terminal productivity";

  hmConfig = {
    home.packages = with pkgs; [
      ripgrep
      fd
      jq
      ncdu
      btdu
      tldr
      ookla-speedtest
      zbar
    ];
  };
}
