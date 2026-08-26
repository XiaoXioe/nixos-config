{
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.agents.auth-agent";
  description = "Secure GUI authentication AI agent root operations";

  options = {
    mode = lib.mkOption {
      type = lib.types.enum [
        "cache-confirm"
        "cache-notify"
        "strict"
        "session-auto"
      ];
      default = "cache-confirm";
      description = "Authentication mode for auth-agent when executed by AI agents";
    };
    timeoutMinutes = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Duration in minutes for which cached authentication credentials remain valid";
    };
    showNotification = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to send a desktop notification when executing root commands";
    };
  };

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;
      cfg =
        if
          hmOpts ? osConfig
          && hmOpts.osConfig ? my
          && hmOpts.osConfig.my ? ai
          && hmOpts.osConfig.my.ai ? agents
          && hmOpts.osConfig.my.ai.agents ? auth-agent
        then
          hmOpts.osConfig.my.ai.agents.auth-agent
        else
          {
            mode = "cache-confirm";
            timeoutMinutes = 15;
            showNotification = true;
          };

      authMode = cfg.mode;
      timeoutMinutes = toString cfg.timeoutMinutes;
      showNotification = if cfg.showNotification then "1" else "0";

      zenityPkg = selfLib.fetchCachePinned "zenity";

      # Private helper executable (kept in Nix Store, not exposed to user PATH)
      authAgentHelper =
        selfLib.mkApp pkgs "auth-agent-helper"
          ''
            B64_PATH="''${B64_PATH:-}"
            B64_ARGS="''${B64_ARGS:-}"
            B64_WAYLAND="''${B64_WAYLAND:-}"
            B64_DISPLAY="''${B64_DISPLAY:-}"

            if [ -z "$B64_ARGS" ]; then
              echo "auth-agent-helper: Error: Tidak ada perintah yang diberikan." >&2
              exit 1
            fi

            mapfile -d "" CMD_ARRAY < <(base64 -d <<< "$B64_ARGS")

            if [ "''${#CMD_ARRAY[@]}" -eq 0 ] || [ -z "''${CMD_ARRAY[0]}" ]; then
              echo "auth-agent-helper: Error: Perintah utama kosong atau tidak valid." >&2
              exit 1
            fi

            # Secure PATH ordering with NixOS setuid wrapper path /run/wrappers/bin first
            DECODED_PATH=$(base64 -d <<< "$B64_PATH")
            export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${user}/bin:$HOME/.nix-profile/bin:$DECODED_PATH:$PATH"

            # Dynamically forward Wayland and X11 display environment
            WAYLAND_DISPLAY=$(base64 -d <<< "$B64_WAYLAND")
            export WAYLAND_DISPLAY
            DISPLAY=$(base64 -d <<< "$B64_DISPLAY")
            export DISPLAY

            XDG_RUNTIME_DIR=/run/user/$(id -u)
            export XDG_RUNTIME_DIR

            # Use NixOS setuid wrapper binary (/run/wrappers/bin/sudo) for root escalation (sudo-rs compatible)
            SUDO_BIN="/run/wrappers/bin/sudo"
            if [ ! -x "$SUDO_BIN" ]; then
              SUDO_BIN=$(command -v sudo || true)
            fi

            if [ -z "$SUDO_BIN" ]; then
              echo "auth-agent: Error: sudo / sudo-rs tidak ditemukan di sistem." >&2
              exit 1
            fi

            DISPLAY_CMD="''${CMD_ARRAY[*]}"
            AUTH_MODE="${authMode}"
            TIMEOUT_MINUTES="${timeoutMinutes}"
            SHOW_NOTIFY="${showNotification}"
            TIMEOUT_SECONDS=$(( TIMEOUT_MINUTES * 60 ))

            CACHE_DIR="/run/user/$(id -u)/auth-agent"
            PASS_FILE="$CACHE_DIR/token"
            TS_FILE="$CACHE_DIR/timestamp"

            NOW=$(${pkgs.coreutils}/bin/date +%s)
            IS_VALID=0
            CACHED_PASS=""

            if [ -f "$PASS_FILE" ] && [ -f "$TS_FILE" ]; then
              LAST_TS=$(${pkgs.coreutils}/bin/cat "$TS_FILE" 2>/dev/null || echo 0)
              AGE=$(( NOW - LAST_TS ))
              if [ "$AGE" -lt "$TIMEOUT_SECONDS" ]; then
                CACHED_PASS=$(${pkgs.coreutils}/bin/cat "$PASS_FILE" 2>/dev/null || true)
                if [ -n "$CACHED_PASS" ]; then
                  IS_VALID=1
                fi
              fi
            fi

            PASS=""

            if [ "$IS_VALID" -eq 1 ] && [ "$AUTH_MODE" != "strict" ]; then
              if [ "$AUTH_MODE" = "cache-confirm" ]; then
                if ! ${zenityPkg}/bin/zenity --question --title="Otorisasi AI (auth-agent)" --text="Agent meminta akses root untuk menjalankan perintah:\n\n[ $DISPLAY_CMD ]\n\nIzinkan eksekusi menggunakan otentikasi ter-cache?" --ok-label="Izinkan" --cancel-label="Batal" </dev/null 2>/dev/null; then
                  echo "auth-agent: Otorisasi dibatalkan oleh pengguna." >&2
                  exit 1
                fi
                PASS="$CACHED_PASS"
              elif [ "$AUTH_MODE" = "cache-notify" ]; then
                if [ "$SHOW_NOTIFY" = "1" ]; then
                  ${pkgs.libnotify}/bin/notify-send -u normal -i security-high "Otorisasi AI (auth-agent)" "Menjalankan perintah root: $DISPLAY_CMD" 2>/dev/null || true
                fi
                PASS="$CACHED_PASS"
              elif [ "$AUTH_MODE" = "session-auto" ]; then
                PASS="$CACHED_PASS"
              fi
            else
              # Force password invalidation if expired or strict
              "$SUDO_BIN" -k 2>/dev/null || true
              if ! PASS=$(${zenityPkg}/bin/zenity --entry --hide-text --title="Otorisasi AI (auth-agent)" --text="Agent meminta akses root untuk menjalankan perintah:\n\n[ $DISPLAY_CMD ]\n\nMasukkan password Anda:" </dev/null 2>/dev/null); then
                echo "auth-agent: Otorisasi dibatalkan oleh pengguna." >&2
                exit 1
              fi
            fi

            if [ -z "$PASS" ]; then
              echo "auth-agent: Otorisasi dibatalkan oleh pengguna." >&2
              exit 1
            fi

            ASKPASS_DIR=$(${pkgs.coreutils}/bin/mktemp -d /tmp/auth-agent-askpass.XXXXXX)
            ${pkgs.coreutils}/bin/chmod 700 "$ASKPASS_DIR"
            ASKPASS_SCRIPT="$ASKPASS_DIR/askpass.sh"

            echo "#!/bin/sh" > "$ASKPASS_SCRIPT"
            echo "echo \"\$AUTH_AGENT_PASS\"" >> "$ASKPASS_SCRIPT"
            ${pkgs.coreutils}/bin/chmod 700 "$ASKPASS_SCRIPT"

            export AUTH_AGENT_PASS="$PASS"
            export SUDO_ASKPASS="$ASKPASS_SCRIPT"

            RUN_CMD=("$SUDO_BIN" "-A" "--preserve-env=PATH,WAYLAND_DISPLAY,XDG_RUNTIME_DIR,DISPLAY" --)
            RUN_CMD+=("''${CMD_ARRAY[@]}")

            set +e
            "''${RUN_CMD[@]}"
            EXIT_CODE=$?
            set -e

            ${pkgs.coreutils}/bin/rm -rf "$ASKPASS_DIR"

            if [ "$EXIT_CODE" -eq 0 ] && [ "$AUTH_MODE" != "strict" ] && [ "$TIMEOUT_SECONDS" -gt 0 ]; then
              ${pkgs.coreutils}/bin/mkdir -p "$CACHE_DIR"
              ${pkgs.coreutils}/bin/chmod 700 "$CACHE_DIR"
              printf '%s' "$PASS" > "$PASS_FILE"
              ${pkgs.coreutils}/bin/chmod 600 "$PASS_FILE"
              printf '%s' "$NOW" > "$TS_FILE"
              ${pkgs.coreutils}/bin/chmod 600 "$TS_FILE"
            elif [ "$EXIT_CODE" -ne 0 ] && [ "$IS_VALID" -eq 0 ]; then
              ${pkgs.coreutils}/bin/rm -rf "$CACHE_DIR" 2>/dev/null || true
            fi

            exit "$EXIT_CODE"
          ''
          [
            pkgs.coreutils
            zenityPkg
            pkgs.libnotify
            pkgs.bash
          ];

      # Public auth-agent command exposed to user PATH
      authAgent =
        selfLib.mkApp pkgs "auth-agent"
          ''
            CACHE_DIR="/run/user/$(id -u)/auth-agent"
            PASS_FILE="$CACHE_DIR/token"
            TS_FILE="$CACHE_DIR/timestamp"
            TIMEOUT_MINUTES="${timeoutMinutes}"
            TIMEOUT_SECONDS=$(( TIMEOUT_MINUTES * 60 ))

            if [ "$1" = "--lock" ] || [ "$1" = "-k" ]; then
              ${pkgs.coreutils}/bin/rm -rf "$CACHE_DIR" 2>/dev/null || true
              echo "auth-agent: Cache otentikasi telah dibatalkan."
              exit 0
            fi

            if [ "$1" = "--status" ]; then
              if [ -f "$PASS_FILE" ] && [ -f "$TS_FILE" ]; then
                NOW=$(${pkgs.coreutils}/bin/date +%s)
                LAST_TS=$(${pkgs.coreutils}/bin/cat "$TS_FILE" 2>/dev/null || echo 0)
                AGE=$(( NOW - LAST_TS ))
                if [ "$AGE" -lt "$TIMEOUT_SECONDS" ]; then
                  REMAINING=$(( TIMEOUT_SECONDS - AGE ))
                  REM_MIN=$(( REMAINING / 60 ))
                  REM_SEC=$(( REMAINING % 60 ))
                  echo "auth-agent: Cache otentikasi AKTIF (Mode: ${authMode}). Sisa waktu: ''${REM_MIN}m ''${REM_SEC}s."
                  exit 0
                fi
              fi
              echo "auth-agent: Cache otentikasi TIDAK AKTIF (Expired / Tidak ada)."
              exit 0
            fi

            if [ "$#" -eq 0 ] || [ -z "$1" ]; then
              echo "Penggunaan: auth-agent [--lock|-k | --status | <perintah> [argumen...]]" >&2
              exit 1
            fi

            B64_PATH=$(printf '%s' "$PATH" | ${pkgs.coreutils}/bin/base64 -w0)
            B64_ARGS=$(printf '%s\0' "$@" | ${pkgs.coreutils}/bin/base64 -w0)
            B64_WAYLAND=$(printf '%s' "''${WAYLAND_DISPLAY:-}" | ${pkgs.coreutils}/bin/base64 -w0)
            B64_DISPLAY=$(printf '%s' "''${DISPLAY:-}" | ${pkgs.coreutils}/bin/base64 -w0)

            exec ${pkgs.openssh}/bin/ssh -F /dev/null -i "$HOME/.ssh/id_ed25519" -q \
              -o StrictHostKeyChecking=no \
              -o UserKnownHostsFile=/dev/null \
              -o ConnectTimeout=5 \
              -o BatchMode=yes \
              -o PreferredAuthentications=publickey \
              "${user}@localhost" \
              "B64_PATH='$B64_PATH' B64_ARGS='$B64_ARGS' B64_WAYLAND='$B64_WAYLAND' B64_DISPLAY='$B64_DISPLAY' ${authAgentHelper}"
          ''
          [
            pkgs.openssh
            pkgs.coreutils
          ];
    in
    {
      home.packages = [
        authAgent
      ];
    };
}
