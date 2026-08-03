{
  pkgs,
  selfLib,
  inputs,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.multiplexers.zellij";
  description = "Zellij multiplexer configuration";

  hmConfig = hmOpts: {
    programs.zellij = {
      enable = true;
      package = inputs.nixpkgs-zellij-043.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zellij;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;

      settings = {
        theme = "catppuccin-mocha";
        pane_frames = false;
        default_layout = "compact";
        show_startup_tips = false;
        show_release_notes = false;

        attach_to_session = true;
        on_force_close = "detach";

        hide_session_name = true;
        ui = {
          pane_frames = {
            hide_session_name = true;
          };
        };

        copy_command = "wl-copy";
        copy_clipboard = "system";
        copy_on_select = true;
        styled_underlines = true;
        mouse_mode = true;
        mirror_session = true;
        scroll_buffer_size = 10000;

        keybinds = {
          "shared_except \"locked\"" = {
            unbind = [ "Ctrl o" ];

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
            "bind \"Alt t\"" = {
              NewTab = { };
            };

            "bind \"Alt d\"" = {
              NewPane = [ "Down" ];
            };
            "bind \"Alt r\"" = {
              NewPane = [ "Right" ];
            };
            "bind \"Alt w\"" = {
              CloseFocus = { };
            };

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
            "bind \"Alt h\"" = {
              MoveFocus = [ "Left" ];
            };
            "bind \"Alt l\"" = {
              MoveFocus = [ "Right" ];
            };
            "bind \"Alt k\"" = {
              MoveFocus = [ "Up" ];
            };
            "bind \"Alt j\"" = {
              MoveFocus = [ "Down" ];
            };

            "bind \"Alt H\"" = {
              Resize = [ "Increase Left" ];
            };
            "bind \"Alt L\"" = {
              Resize = [ "Increase Right" ];
            };
            "bind \"Alt K\"" = {
              Resize = [ "Increase Up" ];
            };
            "bind \"Alt J\"" = {
              Resize = [ "Increase Down" ];
            };

            "bind \"Alt f\"" = {
              ToggleFloatingPanes = { };
            };
            "bind \"Alt z\"" = {
              ToggleFocusFullscreen = { };
            };
            "bind \"Alt s\"" = {
              LaunchOrFocusPlugin = {
                _args = [ "zellij:strider" ];
                floating = true;
              };
            };
            "bind \"Alt o\"" = {
              LaunchOrFocusPlugin = {
                _args = [ "zellij:session-manager" ];
                floating = true;
                move_to_focused_tab = true;
              };
            };
            "bind \"Alt m\"" = {
              LaunchOrFocusPlugin = {
                _args = [ "zellij:session-manager" ];
                floating = true;
                move_to_focused_tab = true;
              };
            };
          };
        };
      };
    };
  };
}
