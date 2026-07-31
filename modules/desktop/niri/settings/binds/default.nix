{
  pkgs,
  selfLib,
  ...
}:
let
  dmsIpc = cmd: sub: args: {
    spawn = [
      "dms"
      "ipc"
      "call"
      cmd
      sub
    ]
    ++ args;
  };

  # 1. Skrip Pemindai Teks (OCR) Presisi Tinggi (ImageMagick Pre-processing + Tesseract --psm 6)
  scanOcrText =
    selfLib.mkApp pkgs "niri-scan-ocr"
      ''
        TMP_RAW=$(mktemp /tmp/ocr_raw_XXXXXX.png)
        TMP_PROC=$(mktemp /tmp/ocr_proc_XXXXXX.png)

        # Tangkap area layar
        grim -g "$(slurp)" "$TMP_RAW" || { rm -f "$TMP_RAW" "$TMP_PROC"; exit 0; }

        # Pra-pemrosesan ImageMagick (Scale 2.5x & Grayscale agar akurasi Tesseract 98%+)
        magick "$TMP_RAW" -resize 250% -colorspace gray -normalize "$TMP_PROC" 2>/dev/null || cp "$TMP_RAW" "$TMP_PROC"

        # Tesseract OCR dengan mode Uniform Block Text (--psm 6)
        TEXT_RESULT=$(tesseract "$TMP_PROC" stdout --psm 6 -l eng+ind 2>/dev/null)
        TRIMMED=$(echo "$TEXT_RESULT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        if [ -n "$TRIMMED" ]; then
          echo -n "$TRIMMED" | wl-copy
          notify-send -a "OCR Scanner" "Teks Terdeteksi (OCR)" "$TRIMMED"
        else
          notify-send -a "OCR Scanner" "Gagal" "Tidak ada teks yang terdeteksi."
        fi

        rm -f "$TMP_RAW" "$TMP_PROC"
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.imagemagick
        pkgs.tesseract
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.gnused
        pkgs.coreutils
      ];

  # 2. Skrip Pemindai QR Code / Barcode Instan
  scanQrCode =
    selfLib.mkApp pkgs "niri-scan-qr"
      ''
        TMP_RAW=$(mktemp /tmp/qr_raw_XXXXXX.png)

        # Tangkap area layar
        grim -g "$(slurp)" "$TMP_RAW" || { rm -f "$TMP_RAW"; exit 0; }

        # Baca QR Code / Barcode via zbarimg
        QR_RESULT=$(zbarimg -q --raw "$TMP_RAW" 2>/dev/null)

        if [ -n "$QR_RESULT" ]; then
          echo -n "$QR_RESULT" | wl-copy
          notify-send -a "QR Scanner" "QR Code Terdeteksi!" "$QR_RESULT"
        else
          notify-send -a "QR Scanner" "Gagal" "Tidak terdeteksi QR Code pada area ini."
        fi

        rm -f "$TMP_RAW"
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.zbar
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.coreutils
      ];

  # 3. Skrip Anotasi Screenshot Interaktif (Satty)
  scanAnnotate =
    selfLib.mkApp pkgs "niri-scan-annotate"
      ''
        grim -g "$(slurp)" - | satty --filename -
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.satty
      ];
in
{
  programs.niri.settings.binds = {
    # Alt+Tab & Recent Windows Binds (from config.kdl, dms/alttab.kdl)
    "Alt+Tab".action.focus-window-previous = [ ];
    "Alt+Shift+Tab".action.focus-window-previous = [ ];
    "Alt+grave".action.focus-window-previous = [ ];
    "Alt+Shift+grave".action.focus-window-previous = [ ];

    # DMS IPC Binds (from dms/binds.kdl)
    "Ctrl+Alt+Delete".action = dmsIpc "processlist" "focusOrToggle" [ ];
    "Ctrl+Shift+R".action = dmsIpc "workspace-rename" "open" [ ];
    "Ctrl+XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "decrement" [ "3" ];
    };
    "Ctrl+XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "increment" [ "3" ];
    };
    "Mod+Alt+Down" = {
      allow-when-locked = true;
      action = dmsIpc "brightness" "decrement" [
        "5"
        ""
      ];
    };
    "Mod+Alt+L".action = dmsIpc "lock" "lock" [ ];
    "Mod+Alt+Up" = {
      allow-when-locked = true;
      action = dmsIpc "brightness" "increment" [
        "5"
        ""
      ];
    };
    "Mod+Comma".action = dmsIpc "settings" "focusOrToggle" [ ];
    "Mod+M".action = dmsIpc "processlist" "focusOrToggle" [ ];
    "Mod+N".action = dmsIpc "notifications" "toggle" [ ];
    "Mod+Shift+N".action = dmsIpc "notepad" "toggle" [ ];
    "Mod+Shift+W".action = dmsIpc "window-rules" "toggle" [ ];
    "Mod+V".action = dmsIpc "clipboard" "toggle" [ ];
    "Mod+Y".action = dmsIpc "dankdash" "wallpaper" [ ];
    "Super+X".action = dmsIpc "powermenu" "toggle" [ ];
    "Super+space".action = dmsIpc "spotlight" "toggle" [ ];
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action = dmsIpc "audio" "decrement" [ "3" ];
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action = dmsIpc "audio" "micmute" [ ];
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action = dmsIpc "audio" "mute" [ ];
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "next" [ ];
    };
    "XF86AudioPause" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "playPause" [ ];
    };
    "XF86AudioPlay" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "playPause" [ ];
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action = dmsIpc "mpris" "previous" [ ];
    };
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action = dmsIpc "audio" "increment" [ "3" ];
    };

    # Workspaces Focus & Move Binds
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    "Mod+I".action.focus-workspace-up = [ ];
    "Mod+U".action.focus-workspace-down = [ ];
    "Mod+Page_Up".action.focus-workspace-up = [ ];
    "Mod+Page_Down".action.focus-workspace-down = [ ];

    "Mod+Shift+I".action.move-workspace-up = [ ];
    "Mod+Shift+U".action.move-workspace-down = [ ];
    "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
    "Mod+Shift+Page_Down".action.move-workspace-down = [ ];

    "Mod+Ctrl+Down".action.move-column-to-workspace-down = [ ];
    "Mod+Ctrl+Up".action.move-column-to-workspace-up = [ ];
    "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];
    "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];

    # Mouse Wheel Binds
    "Mod+WheelScrollDown" = {
      cooldown-ms = 150;
      action.focus-workspace-down = [ ];
    };
    "Mod+WheelScrollUp" = {
      cooldown-ms = 150;
      action.focus-workspace-up = [ ];
    };
    "Mod+Ctrl+WheelScrollDown" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-down = [ ];
    };
    "Mod+Ctrl+WheelScrollUp" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-up = [ ];
    };
    "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
    "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];
    "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
    "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
    "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
    "Mod+WheelScrollLeft".action.focus-column-left = [ ];
    "Mod+WheelScrollRight".action.focus-column-right = [ ];

    # Consuming & Expelling Windows
    "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
    "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
    "Mod+Period".action.expel-window-from-column = [ ];

    # Sizing & Presets
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Shift+Equal".action.set-window-height = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+R".action.switch-preset-column-width = [ ];
    "Mod+Shift+R".action.switch-preset-window-height = [ ];

    # Navigation & Window Management Binds
    "Mod+H".action.focus-column-left = [ ];
    "Mod+L".action.focus-column-right = [ ];
    "Mod+J".action.focus-window-down = [ ];
    "Mod+K".action.focus-window-up = [ ];
    "Mod+Left".action.focus-column-left = [ ];
    "Mod+Right".action.focus-column-right = [ ];
    "Mod+Down".action.focus-window-down = [ ];
    "Mod+Up".action.focus-window-up = [ ];

    "Mod+Shift+H".action.move-column-left = [ ];
    "Mod+Shift+L".action.move-column-right = [ ];
    "Mod+Shift+J".action.move-window-down = [ ];
    "Mod+Shift+K".action.move-window-up = [ ];
    "Mod+Shift+Left".action.move-column-left = [ ];
    "Mod+Shift+Right".action.move-column-right = [ ];
    "Mod+Shift+Down".action.move-window-down = [ ];
    "Mod+Shift+Up".action.move-window-up = [ ];

    "Mod+Home".action.focus-column-first = [ ];
    "Mod+End".action.focus-column-last = [ ];
    "Mod+Ctrl+Home".action.move-column-to-first = [ ];
    "Mod+Ctrl+End".action.move-column-to-last = [ ];
    "Mod+Ctrl+C".action.center-visible-columns = [ ];
    "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];
    "Mod+Ctrl+R".action.reset-window-height = [ ];

    "Mod+Q" = {
      repeat = false;
      action.close-window = [ ];
    };
    "Mod+F".action.maximize-column = [ ];
    "Mod+Shift+F".action.fullscreen-window = [ ];
    "Mod+Shift+T".action.toggle-window-floating = [ ];
    "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];
    "Mod+W".action.toggle-column-tabbed-display = [ ];
    "Mod+C".action.center-column = [ ];

    # Monitor Focus & Move Binds
    "Mod+Ctrl+H".action.focus-monitor-left = [ ];
    "Mod+Ctrl+L".action.focus-monitor-right = [ ];
    "Mod+Ctrl+J".action.focus-monitor-down = [ ];
    "Mod+Ctrl+K".action.focus-monitor-up = [ ];
    "Mod+Ctrl+Left".action.focus-monitor-left = [ ];
    "Mod+Ctrl+Right".action.focus-monitor-right = [ ];

    "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
    "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];
    "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
    "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
    "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
    "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
    "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
    "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];

    # Launchers & Utility Binds
    "Mod+E".action.spawn = [
      "bash"
      "-c"
      "bemoji -t"
    ];
    "Mod+T".action.spawn = "kitty";
    "Super+B".action.spawn = "zen-beta";
    "Mod+Tab" = {
      repeat = false;
      action.toggle-overview = [ ];
    };
    "Mod+Escape" = {
      allow-inhibiting = false;
      action.toggle-keyboard-shortcuts-inhibit = [ ];
    };
    "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

    # Power & Utility Binds
    "Mod+Shift+P".action.power-off-monitors = [ ];

    # Screenshot Binds
    "Alt+Print".action.screenshot-window = [ ];
    "Alt+XF86Launch1".action.screenshot-window = [ ];
    "Ctrl+Print".action.screenshot-screen = [ ];
    "Ctrl+XF86Launch1".action.screenshot-screen = [ ];
    "Ctrl+Shift+S".action.spawn = [ "${scanOcrText}" ];
    "Ctrl+Shift+Q".action.spawn = [ "${scanQrCode}" ];
    "Mod+Shift+A".action.spawn = [ "${scanAnnotate}" ];
    "Super+Shift+S".action.screenshot = [ ];
    "XF86Launch1".action.screenshot = [ ];
    "Mod+Shift+E".action.quit = [ ];
  };
}
