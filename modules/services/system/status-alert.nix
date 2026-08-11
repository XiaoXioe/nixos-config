{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.system.status-alert";
  description = "Systemd service failure desktop notifier";

  nixosConfig =
    let
      userName = config.my.user.name;
      uid = toString config.users.users.${userName}.uid;
    in
    {
      # System-level Failure Notifier (runs as root, escalates to user using active sudo wrapper)
      systemd.services."status-alert@" = {
        description = "Status Alert for %i";
        unitConfig = {
          DefaultDependencies = false;
        };
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          PrivateTmp = true;
          ProtectSystem = "full";
          NoNewPrivileges = true;
          ExecStart = "${
            selfLib.mkApp pkgs "send-status-alert" ''
              service_name="$1"
              echo "ALERT: Service $service_name has FAILED!"

              # Cari setuid wrapper sudo yang aktif (untuk kompatibilitas sudo-rs)
              SUDO_BIN="/run/wrappers/bin/sudo"
              if [ ! -x "$SUDO_BIN" ]; then
                SUDO_BIN="sudo"
              fi

              if [ -S "/run/user/${uid}/bus" ]; then
                "$SUDO_BIN" -u ${userName} \
                  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" \
                  ${pkgs.libnotify}/bin/notify-send \
                  -u critical \
                  -i dialog-error \
                  "System Failure: $service_name" \
                  "Service $service_name failed. Check journalctl -u $service_name for details."
              fi
            '' [ pkgs.libnotify ]
          } %i";
        };
      };

      # User-level Failure Notifier (runs within user session, calls notify-send directly without sudo)
      systemd.user.services."status-alert@" = {
        description = "User Status Alert for %i";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${
            selfLib.mkApp pkgs "send-user-status-alert" ''
              service_name="$1"
              echo "ALERT: User service $service_name has FAILED!"

              if [ -S "/run/user/$UID/bus" ] || [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
                ${pkgs.libnotify}/bin/notify-send \
                  -u critical \
                  -i dialog-error \
                  "User System Failure: $service_name" \
                  "User service $service_name failed. Check journalctl --user -u $service_name for details."
              fi
            '' [ pkgs.libnotify ]
          } %i";
        };
      };
    };
}
