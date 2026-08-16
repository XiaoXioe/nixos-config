{
  config,
  lib,
  pkgs,
  ...
}:

let
  userName = config.my.user.name;

  isNiriEnabled = config.my.desktop ? niri;
  dmsEnabled = isNiriEnabled && config.my.desktop.niri ? dms && config.my.desktop.niri.dms.enable;
  noctaliaEnabled =
    isNiriEnabled && config.my.desktop.niri ? noctalia && config.my.desktop.niri.noctalia.enable;

  configDir = "/home/${userName}/.config/niri";

  # Hot-swap shell switcher script
  niriShellSwitch = pkgs.writeShellScriptBin "niri-shell-switch" ''
    CONFIG_DIR="${configDir}"
    PGREP="${pkgs.procps}/bin/pgrep"
    PKILL="${pkgs.procps}/bin/pkill"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    NIRI="${pkgs.niri}/bin/niri"

    # Detect current shell (NixOS wraps binaries, use -f for command matching)
    CURRENT="none"
    if $PGREP -f "bin/noctalia" > /dev/null 2>&1; then
      CURRENT="noctalia"
    elif $PGREP -f "bin/dms" > /dev/null 2>&1; then
      CURRENT="dms"
    fi

    # Determine target (explicit arg or toggle)
    if [ "$1" = "dms" ] || [ "$1" = "noctalia" ]; then
      TARGET="$1"
    elif [ "$CURRENT" = "noctalia" ]; then
      TARGET="dms"
    elif [ "$CURRENT" = "dms" ]; then
      TARGET="noctalia"
    else
      TARGET="noctalia"
    fi

    # Skip if already on target
    if [ "$CURRENT" = "$TARGET" ]; then
      $NOTIFY -t 2000 "Shell Switch" "Already on $TARGET" 2>/dev/null
      exit 0
    fi

    $NOTIFY -t 2000 "Shell Switch" "Switching: $CURRENT → $TARGET" 2>/dev/null

    # Kill current shell and its children (use -f for NixOS wrapped binaries)
    case "$CURRENT" in
      noctalia) $PKILL -f "bin/noctalia" 2>/dev/null ;;
      dms)      $PKILL -f "bin/dms" 2>/dev/null
                $PKILL -f "quickshell.*dms" 2>/dev/null ;;
    esac

    # Wait for processes to fully terminate
    sleep 0.8

    # Start new shell & reload niri config
    case "$TARGET" in
      dms)
        dms run &
        disown
        sleep 0.5
        $NIRI msg action load-config-file --path "$CONFIG_DIR/config-dms.kdl"
        ;;
      noctalia)
        noctalia &
        disown
        sleep 0.5
        $NIRI msg action load-config-file --path "$CONFIG_DIR/config-noctalia.kdl"
        ;;
    esac

    $NOTIFY -t 3000 "Shell Switch" "Switched to $TARGET ✓" 2>/dev/null
  '';

  # Session wrappers
  niriDmsWrapper = pkgs.writeShellScriptBin "niri-session-dms" ''
    export NIRI_CONFIG="${configDir}/config-dms.kdl"
    exec niri-session
  '';

  niriNoctaliaWrapper = pkgs.writeShellScriptBin "niri-session-noctalia" ''
    export NIRI_CONFIG="${configDir}/config-noctalia.kdl"
    exec niri-session
  '';

  # Desktop entries
  niriDmsSession =
    pkgs.runCommand "niri-dms-session"
      {
        passthru.providedSessions = [ "niri-dms" ];
      }
      ''
            mkdir -p $out/share/wayland-sessions
            cat > $out/share/wayland-sessions/niri-dms.desktop <<'EOF'
        [Desktop Entry]
        Name=Niri (DMS)
        Comment=A scrollable-tiling Wayland compositor (DankMaterialShell)
        Exec=${niriDmsWrapper}/bin/niri-session-dms
        Type=Application
        DesktopNames=niri
        EOF
      '';

  niriNoctaliaSession =
    pkgs.runCommand "niri-noctalia-session"
      {
        passthru.providedSessions = [ "niri-noctalia" ];
      }
      ''
            mkdir -p $out/share/wayland-sessions
            cat > $out/share/wayland-sessions/niri-noctalia.desktop <<'EOF'
        [Desktop Entry]
        Name=Niri (Noctalia)
        Comment=A scrollable-tiling Wayland compositor (Noctalia shell)
        Exec=${niriNoctaliaWrapper}/bin/niri-session-noctalia
        Type=Application
        DesktopNames=niri
        EOF
      '';
in
{
  config = lib.mkIf (dmsEnabled || noctaliaEnabled) {
    services.displayManager.sessionPackages =
      (lib.optional dmsEnabled niriDmsSession) ++ (lib.optional noctaliaEnabled niriNoctaliaSession);

    # Shell switch script available system-wide
    environment.systemPackages = [ niriShellSwitch ];
  };
}
