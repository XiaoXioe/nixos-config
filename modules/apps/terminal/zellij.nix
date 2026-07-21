{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.zellij";
  description = "Zellij multiplexer configuration";

  hmConfig = hmOpts: {
    programs.zellij = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;

      settings = {
        theme = "catppuccin-mocha";
        pane_frames = false;
        default_layout = "compact"; # Tampilan bersih: hanya tab di atas, tanpa status bar di bawah
        show_startup_tips = false; # Matikan popup tips/welcome saat startup

        keybinds = {
          "shared_except \"locked\"" = {
            unbind = [ "Ctrl o" ];

            # Tab Management
            "bind \"Ctrl PageDown\"" = {
              GoToNextTab = { };
            };
            "bind \"Ctrl PageUp\"" = {
              GoToPreviousTab = { };
            };
            "bind \"Ctrl Shift PageDown\"" = {
              MoveTab = [ "Right" ];
            };
            "bind \"Ctrl Shift PageUp\"" = {
              MoveTab = [ "Left" ];
            };
            "bind \"Ctrl n\"" = {
              NewTab = { };
            };
            "bind \"Ctrl w\"" = {
              CloseTab = { };
            };
            "bind \"Ctrl t\"" = {
              NewTab = { };
            };

            # 1. Split Pane (Membelah Layar)
            "bind \"Alt d\"" = {
              NewPane = [ "Down" ];
            };
            "bind \"Alt r\"" = {
              NewPane = [ "Right" ];
            };
            "bind \"Alt w\"" = {
              CloseFocus = { };
            };

            # 2. Fast Focus (Pindah Antar Pane)
            "bind \"Alt Left\"" = {
              MoveFocus = [ "Left" ];
            };
            "bind \"Alt Right\"" = {
              MoveFocus = [ "Right" ];
            };
            "bind \"Alt Up\"" = {
              MoveFocus = [ "Up" ];
            };
            "bind \"Alt Down\"" = {
              MoveFocus = [ "Down" ];
            };

            # 3. Floating Terminal (Melayang)
            "bind \"Alt f\"" = {
              ToggleFloatingPanes = { };
            };

            # 4. Zoom Pane (Layar Penuh Sementara)
            "bind \"Alt z\"" = {
              ToggleFocusFullscreen = { };
            };
          };
        };
      };
    };
  };
}
