{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.flatpak;

  # Script inisialisasi remote Flathub dan global sandbox overrides
  flatpakSetupApp =
    selfLib.mkApp pkgs "flatpak-system-setup"
      ''
        if ! flatpak remote-list --system | grep -q "^flathub"; then
          echo "==> [flatpak-setup] Adding Flathub remote..."
          flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        else
          echo "==> [flatpak-setup] Flathub remote already configured."
        fi
      ''
      [
        pkgs.flatpak
        pkgs.gnugrep
        pkgs.coreutils
      ];
in
selfLib.mkModule {
  name = "services.flatpak";
  description = "Core Flatpak daemon, persistent BTRFS storage, and Flathub initialization";

  preservation = {
    persist = true;
    directories = [
      "/var/lib/flatpak"
    ];
    userDirectories = [
      ".var/app"
      ".local/share/flatpak"
    ];
  };

  options = {
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically update Flatpaks on a daily schedule.";
    };
  };

  nixosConfig = {
    # Aktifkan daemon flatpak bawaan NixOS
    services.flatpak.enable = true;

    # Optimasi NoCoW Btrfs untuk direktori data flatpak pengguna
    my.services.storage.btrfs-nocow-migration.nocowDirectories = [
      ".var/app"
    ];

    # Services via systemd
    systemd = {

      services = {
        # Layanan oneshot untuk inisialisasi remote Flathub dan global overrides
        flatpak-system-setup = {
          description = "Configure default Flathub remote and global sandbox overrides";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network-online.target"
            "var-lib-flatpak.mount"
          ];
          wants = [ "network-online.target" ];
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${flatpakSetupApp}";
          };
        };

        # Layanan update harian opsional jika autoUpdate diaktifkan
        flatpak-auto-update = lib.mkIf cfg.autoUpdate {
          description = "Automatic Flatpak applications and runtimes update";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.flatpak}/bin/flatpak update -y --noninteractive";
          };
        };
      };

      timers = {
        flatpak-auto-update = lib.mkIf cfg.autoUpdate {
          description = "Timer for automatic Flatpak update";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
    };
  };
}
