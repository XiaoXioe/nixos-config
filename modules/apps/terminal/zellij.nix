{
  pkgs,
  selfLib,
  ...
}:

let
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm";
    sha256 = "16v6ascpyl7na6lp3v98haggp9lwsg6r1rlv40zcyqpd3p7dxkhw";
  };
in
selfLib.mkModule {
  name = "apps.terminal.zellij";
  description = "Zellij multiplexer configuration";

  hmConfig = hmOpts: {
    home.activation.zellijPermissions = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.cache/zellij
      $DRY_RUN_CMD rm -f $HOME/.cache/zellij/permissions.kdl
      $DRY_RUN_CMD cp -f $HOME/.config/zellij/permissions.kdl $HOME/.cache/zellij/permissions.kdl 2>/dev/null || true
      $DRY_RUN_CMD chmod 644 $HOME/.cache/zellij/permissions.kdl 2>/dev/null || true
    '';

    # Stable symlink: path tetap konsisten meskipun hash Nix Store berubah setelah flake update
    xdg.configFile."zellij/plugins/zjstatus.wasm".source = zjstatus;

    programs.zellij = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;

      settings = {
        theme = "catppuccin-mocha";
        pane_frames = false;
        default_layout = "compact";
        show_startup_tips = false;

        attach_to_session = true;
        on_force_close = "quit";

        hide_session_name = true;
        ui = {
          pane_frames = {
            hide_session_name = true;
          };
        };

        plugins = {
          zjstatus.location = "file:${zjstatus}";
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

    xdg.configFile."zellij/permissions.kdl".text = ''
      "${zjstatus}" {
          ChangeApplicationState
          ReadApplicationState
          RunCommands
      }
    '';

    xdg.configFile."zellij/layouts/default.kdl".text = ''
      layout {
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="file:${zjstatus}" {
                      format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                      format_center "#[fg=#181825]#[bg=#181825]{tabs}#[fg=#181825]"
                      format_right  "{command_git_branch} {datetime}"
                      format_space  ""

                      border_enabled  "false"
                      border_char     "─"
                      border_format   "#[fg=#6C7086]{char}"
                      border_position "top"

                      hide_frame_for_single_pane "false"

                      mode_normal        "#[bg=#89B4FA,fg=#1E1E2E,bold] NORMAL "
                      mode_locked        "#[bg=#F38BA8,fg=#1E1E2E,bold] LOCKED "
                      mode_resize        "#[bg=#FAB387,fg=#1E1E2E,bold] RESIZE "
                      mode_pane          "#[bg=#A6E3A1,fg=#1E1E2E,bold] PANE "
                      mode_tab           "#[bg=#F9E2AF,fg=#1E1E2E,bold] TAB "
                      mode_scroll        "#[bg=#CBA6F7,fg=#1E1E2E,bold] SCROLL "
                      mode_session       "#[bg=#94E2D5,fg=#1E1E2E,bold] SESSION "
                      mode_move          "#[bg=#F5C2E7,fg=#1E1E2E,bold] MOVE "
                      mode_tmux          "#[bg=#FAB387,fg=#1E1E2E,bold] TMUX "

                      tab_normal             "#[fg=#89B4FA,bg=#181825,bold] {index} #[fg=#CDD6F4,bg=#181825]{name} "
                      tab_active             "#[fg=#1E1E2E,bg=#89B4FA,bold] {index} #[fg=#1E1E2E,bg=#89B4FA,bold]{name} "
                      tab_active_fullscreen  "#[fg=#1E1E2E,bg=#A6E3A1,bold] {index} #[fg=#1E1E2E,bg=#A6E3A1,bold]{name} [Z] "
                      tab_active_sync        "#[fg=#1E1E2E,bg=#F9E2AF,bold] {index} #[fg=#1E1E2E,bg=#F9E2AF,bold]{name} [S] "

                      tab_display_count         "5"
                      tab_truncate_start_format "#[fg=#1E1E2E,bg=#FAB387,bold] < +{count} "
                      tab_truncate_end_format   "#[fg=#1E1E2E,bg=#FAB387,bold] +{count} > "

                      datetime        "#[fg=#6C7086,bold] {format} "
                      datetime_format "%A, %d %b %Y %H:%M"
                      datetime_timezone "Asia/Jakarta"
                   }
              }
          }
      }
    '';
  };
}
