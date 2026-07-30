{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.tools";
  description = "Modern command-line utilities and tools for terminal productivity";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      ripgrep
      fd
      jq
      ncdu
      btdu
      tldr
      bat
      ookla-speedtest
      bmon
      tdl
      bemoji
      wtype
      fuzzel
      tesseract
      slurp
      grim
      wl-clipboard
    ];
  };
}
