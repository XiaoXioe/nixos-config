{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.auth-agent";
  description = "Secure GUI authentication AI agent root operations";

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;

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

            # Invalidate any cached sudo timestamp so GUI authentication is always required
            "$SUDO_BIN" -k 2>/dev/null || true

            DISPLAY_CMD="''${CMD_ARRAY[*]}"
            PASS=""
            if ! PASS=$(${pkgs.zenity}/bin/zenity --entry --hide-text --title="Otorisasi AI (auth-agent)" --text="Agent meminta akses root untuk menjalankan perintah:\n\n[ $DISPLAY_CMD ]\n\nMasukkan password Anda:" </dev/null 2>/dev/null); then
              echo "auth-agent: Otorisasi dibatalkan oleh pengguna." >&2
              exit 1
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
            exit "$EXIT_CODE"
          ''
          [
            pkgs.coreutils
            pkgs.zenity
            pkgs.bash
          ];

      # Public auth-agent command exposed to user PATH
      authAgent =
        selfLib.mkApp pkgs "auth-agent"
          ''
            if [ "$#" -eq 0 ] || [ -z "$1" ]; then
              echo "Penggunaan: auth-agent <perintah> [argumen...]" >&2
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
