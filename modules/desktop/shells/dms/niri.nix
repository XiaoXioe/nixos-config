{ osConfig, lib, ... }:
let
  d = osConfig.my.desktop;
  isEnabled =
    (d ? niri && d.niri ? dms && d.niri.dms.enable)
    || (d ? shells && d.shells ? dms && d.shells.dms.enable);
in
{
  xdg.configFile."niri/config-dms.kdl" = lib.mkIf isEnabled {
    text = ''
      // Niri Session: DankMaterialShell
      include "config.kdl"

      spawn-at-startup "dms" "run"

      binds {
          Ctrl+Alt+Delete { spawn "dms" "ipc" "call" "processlist" "focusOrToggle"; }
          Ctrl+Shift+R { spawn "dms" "ipc" "call" "workspace-rename" "open"; }
          Ctrl+XF86AudioLowerVolume allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "decrement" "2"; }
          Ctrl+XF86AudioRaiseVolume allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "increment" "2"; }
          Mod+Alt+Down allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "decrement" "5" ""; }
          Mod+Alt+L { spawn "dms" "ipc" "call" "lock" "lock"; }
          Mod+Alt+Up allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "increment" "5" ""; }
          Mod+Comma { spawn "dms" "ipc" "call" "settings" "focusOrToggle"; }
          Mod+M { spawn "dms" "ipc" "call" "processlist" "focusOrToggle"; }
          Mod+N { spawn "dms" "ipc" "call" "notifications" "toggle"; }
          Mod+Shift+N { spawn "dms" "ipc" "call" "notepad" "toggle"; }
          Mod+Shift+I { spawn "dms" "ipc" "call" "session" "toggleIdleInhibit"; }
          Mod+Shift+W { spawn "dms" "ipc" "call" "window-rules" "toggle"; }
          Mod+V { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
          Mod+Y { spawn "dms" "ipc" "call" "dankdash" "wallpaper"; }
          Super+X { spawn "dms" "ipc" "call" "powermenu" "toggle"; }
          Super+Space { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "3"; }
          XF86AudioMicMute allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "micmute"; }
          XF86AudioMute allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "mute"; }
          XF86AudioNext allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "next"; }
          XF86AudioPause allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "playPause"; }
          XF86AudioPlay allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "playPause"; }
          XF86AudioPrev allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "previous"; }
          XF86AudioRaiseVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "3"; }
      }
    '';
  };
}
