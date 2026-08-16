{ osConfig, lib, ... }:

let
  isNoctalia =
    (
      osConfig.my.desktop ? niri
      && osConfig.my.desktop.niri ? noctalia
      && osConfig.my.desktop.niri.noctalia.enable
    )
    || (
      osConfig.my.desktop ? shells
      && osConfig.my.desktop.shells ? noctalia
      && osConfig.my.desktop.shells.noctalia.enable
    );
in
{
  xdg.configFile."niri/config-noctalia.kdl" = lib.mkIf isNoctalia {
    text = ''
      // Niri Session: Noctalia v5
      include "config.kdl"

      spawn-at-startup "noctalia"

      binds {
          Super+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
          Super+Period { spawn "noctalia" "msg" "panel-toggle" "launcher" "/emo"; }
          Super+X { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
          Mod+N { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
          Mod+A { spawn "noctalia" "msg" "panel-toggle" "control-center" "notifications"; }
          Mod+V { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
          Ctrl+Super+T { spawn "noctalia" "msg" "panel-toggle" "wallpaper"; }
          Mod+Shift+W { spawn "noctalia" "msg" "panel-toggle" "wallpaper"; }
          Mod+Z { spawn "noctalia" "msg" "settings-toggle"; }
          Mod+I { spawn "noctalia" "msg" "settings-toggle"; }
          Mod+Tab { spawn "noctalia" "msg" "window-switcher"; }
          Mod+Alt+C { spawn "noctalia" "msg" "panel-toggle" "session"; }
          Mod+Alt+L { spawn "noctalia" "msg" "session" "lock"; }
          Print { spawn "noctalia" "msg" "screenshot-region"; }
          Super+Shift+S { spawn "noctalia" "msg" "screenshot-region"; }
          Ctrl+Print { spawn "noctalia" "msg" "screenshot-fullscreen"; }
          Super+Print { spawn "noctalia" "msg" "screenshot-fullscreen"; }
          XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up" "2"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down" "2"; }
          XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
          XF86AudioMicMute allow-when-locked=true { spawn "noctalia" "msg" "mic-mute"; }
          XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia" "msg" "brightness-up"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia" "msg" "brightness-down"; }
          XF86AudioPlay allow-when-locked=true { spawn "noctalia" "msg" "media" "toggle"; }
          XF86AudioNext allow-when-locked=true { spawn "noctalia" "msg" "media" "next"; }
          XF86AudioPrev allow-when-locked=true { spawn "noctalia" "msg" "media" "previous"; }
      }
    '';
  };
}
