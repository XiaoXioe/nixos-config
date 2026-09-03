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
      "${config.my.dataPath}/flatpak-userdata"
    ];

    # Bind-mount direktori sistem Flatpak ke penyimpanan persisten /mnt/data_btrfs
    fileSystems."/var/lib/flatpak" = {
      device = "${config.my.dataPath}/flatpak-system";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.requires=${
          lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" config.my.dataPath)
        }.mount"
        "x-systemd.after=${
          lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" config.my.dataPath)
        }.mount"
        "x-systemd.before=local-fs.target"
      ];
    };

    # Aturan pembuatan direktori, symlink persisten, dan services via systemd
    systemd = {
      tmpfiles.rules = [
        "d ${config.my.dataPath}/flatpak-system 0755 root root - -"
        "d ${config.my.dataPath}/flatpak-userdata 0755 ${config.my.user.name} users - -"
        "d ${config.my.dataPath}/flatpak-local 0755 ${config.my.user.name} users - -"
        "d /home/${config.my.user.name}/.var 0755 ${config.my.user.name} users - -"
        "d /home/${config.my.user.name}/.local 0755 ${config.my.user.name} users - -"
        "d /home/${config.my.user.name}/.local/share 0755 ${config.my.user.name} users - -"
        "L+ /home/${config.my.user.name}/.var/app - - - - ${config.my.dataPath}/flatpak-userdata"
        "L+ /home/${config.my.user.name}/.local/share/flatpak - - - - ${config.my.dataPath}/flatpak-local"
      ];

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
