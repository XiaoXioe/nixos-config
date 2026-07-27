{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.fzf";
  description = "FZF interactive fuzzy finder for shell";

  hmConfig = hmOpts: {
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;
      colors = {
        "bg+" = "#3b4252";
        "fg+" = "#e5e9f0";
        "hl+" = "#81a1c1";
        "pointer" = "#b48ead";
        "marker" = "#a3be8c";
      };
      defaultOptions = [
        "--preview 'echo {}'"
        "--preview-window down:3:wrap"
      ];
    };
  };
}
