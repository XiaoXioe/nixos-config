{
  config,
  lib,
  selfLib,
  allUsers,
  ...
}:
let
  persistBase = "/persist";

  btrfsDevice = "/dev/disk/by-uuid/f888825f-bdb2-4dca-9c58-b5dd4f6a39d8";
  rootSubvol = "@nixos-root";
  homeSubvol = "@nixos-home";

  # Wipe root & home subvolumes on each boot, preserving pre-wipe home snapshot
  wipeRootScript = ''
    echo "==> [preservation] Wiping ephemeral root and home subvolumes..."
    mkdir -p /btrfs_tmp

    # Mount fisik disk BTRFS di initrd
    mount -t btrfs -o subvol=/ ${btrfsDevice} /btrfs_tmp

    timestamp=$(date "+%Y-%m-%d_%H:%M:%S")
    mkdir -p /btrfs_tmp/@nixos-old-roots

    # Wipe Root
    if [[ -e /btrfs_tmp/${rootSubvol} ]]; then
      echo "==> [preservation] Moving old root to @nixos-old-roots/root-$timestamp"
      mv /btrfs_tmp/${rootSubvol} "/btrfs_tmp/@nixos-old-roots/root-$timestamp"
    fi
    btrfs subvolume create /btrfs_tmp/${rootSubvol}

    # Pre-wipe home snapshot → saved in persist for recovery
    # Accessible at /persist/home-snapshots/ after boot.
    if [[ -e /btrfs_tmp/${homeSubvol} ]] && [[ -e /btrfs_tmp/@nixos-persist ]]; then
      echo "==> [preservation] Snapshotting home before wipe → @nixos-persist/home-snapshots/$timestamp"
      mkdir -p /btrfs_tmp/@nixos-persist/home-snapshots
      btrfs subvolume snapshot -r \
        /btrfs_tmp/${homeSubvol} \
        "/btrfs_tmp/@nixos-persist/home-snapshots/$timestamp"

      # Delete old home snapshots (keep last 10)
      old_snaps=$(ls -1dt /btrfs_tmp/@nixos-persist/home-snapshots/* 2>/dev/null | tail -n +11)
      for snap in $old_snaps; do
        echo "==> [preservation] Deleting old home snapshot: $snap"
        btrfs subvolume delete "$snap"
      done
    fi

    # Wipe Home
    if [[ -e /btrfs_tmp/${homeSubvol} ]]; then
      echo "==> [preservation] Moving old home to @nixos-old-roots/home-$timestamp"
      mv /btrfs_tmp/${homeSubvol} "/btrfs_tmp/@nixos-old-roots/home-$timestamp"
    fi
    btrfs subvolume create /btrfs_tmp/${homeSubvol}

    # Delete excess old root/home backups (keep last 20)
    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    cleanup_old_backups() {
      prefix=$1
      backups=$(ls -1d /btrfs_tmp/@nixos-old-roots/$prefix-* 2>/dev/null | sort -r | tail -n +21)
      for i in $backups; do
        echo "==> [preservation] Deleting old $prefix backup: $i"
        delete_subvolume_recursively "$i"
      done
    }

    cleanup_old_backups "root"
    cleanup_old_backups "home"

    umount /btrfs_tmp
    echo "==> [preservation] Ephemeral root and home ready."
  '';
in
selfLib.mkModule {
  name = "hardware.preservation";
  options = {
    ephemeralRoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to wipe the root subvolume (${rootSubvol}) on every boot.
        Uses a systemd initrd service.
      '';
    };
    extraDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Additional system directories to persist under /persist.";
    };
    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Additional system files to persist under /persist.";
    };
  };

  nixosConfig = let
    cfg = config.my.hardware.preservation;
  in {
    boot.initrd.systemd.enable = true;
    boot.initrd.systemd.services.wipe-btrfs-root = lib.mkIf cfg.ephemeralRoot {
      description = "Wipe BTRFS root and home subvolumes";
      wantedBy = [ "initrd.target" ];
      after = [ "initrd-root-device.target" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeRootScript;
    };
    boot.initrd.supportedFilesystems = lib.mkIf cfg.ephemeralRoot [ "btrfs" ];

    preservation.enable = true;
    preservation.preserveAt."${persistBase}" = {
      directories = [
        "/var/lib/nixos"
        "/var/lib/sddm"
        "/var/lib/systemd"
        "/var/lib/NetworkManager"
        "/var/lib/9router"
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/waydroid"
        "/root"
        "/var/lib/libvirt"
        "/var/lib/vnstat"
        "/var/lib/tor"
        {
          directory = "/var/lib/private/ollama";
          mode = "0700";
        }
        {
          directory = "/var/lib/private/open-webui";
          mode = "0700";
        }
      ]
      ++ cfg.extraDirectories;

      files = [
        {
          file = "/etc/machine-id";
          # machine-id must be available very early in initrd
          inInitrd = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          # Use symlink to preserve SSH key permissions (0600)
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key.pub";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key.pub";
          how = "symlink";
          configureParent = true;
        }
      ]
      ++ cfg.extraFiles;

      users = lib.mapAttrs (_name: _userCfg: {
        directories = [
          "Desktop"
          ".BurpSuite"
          ".config"
          ".claude"
          ".codex"
          ".java"
          ".local/share"
          ".local/state"
          ".librewolf"
          ".steam"
          ".vscode-oss"
          ".cache/nix"
          ".cache/mozilla"
          ".cache/rclone"
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".gnupg";
            mode = "0700";
          }
          {
            directory = ".android";
            mode = "0700";
          }
          "PersistentData"
          ".antigravity"
          ".gemini"
          "nixos-config"
          "nix-custompkgs"
          "nix-custompkg-priv"
          "freqtrade-dev"
        ];
        files = [
          "link.txt"
          ".bash_history"
          ".claude.json"
        ];
      }) allUsers;
    };
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
