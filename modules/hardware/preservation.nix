{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  persistBase = "/persist";

  rootSubvol = "@nixos-root";
  homeSubvol = "@nixos-home";
  keepHome = 10;
  keepRoot = 20;
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

  nixosConfig =
    let
      cfg = config.my.hardware.preservation;
      btrfsDevice = config.fileSystems."/".device;

      # Instant wipe in initrd (only renames and snapshot creation)
      wipeRootScript = ''
        echo "==> [preservation] Wiping ephemeral root and home subvolumes..."
        mkdir -p /btrfs_tmp

        # Mount BTRFS root
        mount -t btrfs -o subvol=/ ${btrfsDevice} /btrfs_tmp

        timestamp=$(date "+%Y-%m-%d_%H:%M:%S")
        mkdir -p /btrfs_tmp/@nixos-old-roots

        # Wipe Root
        if [[ -e /btrfs_tmp/${rootSubvol} ]]; then
          echo "==> [preservation] Moving old root to @nixos-old-roots/root-$timestamp"
          mv /btrfs_tmp/${rootSubvol} "/btrfs_tmp/@nixos-old-roots/root-$timestamp"
        fi
        btrfs subvolume create /btrfs_tmp/${rootSubvol}

        # Pre-wipe home snapshot
        if [[ -e /btrfs_tmp/${homeSubvol} ]] && [[ -e /btrfs_tmp/@nixos-persist ]]; then
          echo "==> [preservation] Snapshotting home before wipe → @nixos-persist/home-snapshots/$timestamp"
          mkdir -p /btrfs_tmp/@nixos-persist/home-snapshots
          btrfs subvolume snapshot -r \
            /btrfs_tmp/${homeSubvol} \
            "/btrfs_tmp/@nixos-persist/home-snapshots/$timestamp"
        fi

        # Wipe Home
        if [[ -e /btrfs_tmp/${homeSubvol} ]]; then
          echo "==> [preservation] Moving old home to @nixos-old-roots/home-$timestamp"
          mv /btrfs_tmp/${homeSubvol} "/btrfs_tmp/@nixos-old-roots/home-$timestamp"
        fi
        btrfs subvolume create /btrfs_tmp/${homeSubvol}

        umount /btrfs_tmp
        echo "==> [preservation] Ephemeral root and home ready."
      '';
    in
    {
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

      # Offload slow recursive BTRFS deletions to a background post-boot service
      systemd.services.preservation-cleanup = lib.mkIf cfg.ephemeralRoot {
        description = "Background cleanup of old BTRFS roots and home backups";
        after = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [
          "/run/wrappers/bin"
        ]
        ++ (with pkgs; [
          btrfs-progs
          coreutils
          util-linux
        ]);
        serviceConfig = {
          Type = "oneshot";
          PrivateMounts = true;
          RuntimeDirectory = "btrfs_cleanup";
          ExecStart = pkgs.writeShellScript "preservation-cleanup" ''
            set -euo pipefail
            echo "==> [preservation] Starting background cleanup..."

            # Mount point managed by RuntimeDirectory (auto-cleaned on exit)
            MNTDIR="/run/btrfs_cleanup"
            mount -t btrfs -o subvol=/ ${btrfsDevice} "$MNTDIR"

            delete_subvolume_recursively() {
              local IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' ' || true); do
                delete_subvolume_recursively "$MNTDIR/$i"
              done
              if [ -e "$1" ]; then
                btrfs subvolume delete "$1" || true
              fi
            }

            cleanup_old_backups() {
              prefix=$1
              keep=$2
              ls -1d "$MNTDIR/@nixos-old-roots/$prefix-"* 2>/dev/null | sort -r | tail -n +$((keep + 1)) | while read -r i; do
                [ -n "$i" ] || continue
                echo "Deleting old $prefix backup: $i"
                delete_subvolume_recursively "$i"
              done
            }

            # Delete old home snapshots (keep last 10)
            ls -1dt "$MNTDIR/@nixos-persist/home-snapshots/"* 2>/dev/null | tail -n +${toString (keepHome + 1)} | while read -r snap; do
              [ -n "$snap" ] || continue
              echo "Deleting old home snapshot: $snap"
              btrfs subvolume delete "$snap"
            done

            cleanup_old_backups "root" ${toString keepRoot}
            cleanup_old_backups "home" ${toString keepHome}

            umount "$MNTDIR"
            echo "==> [preservation] Background cleanup finished."
          '';
        };
      };

      preservation.enable = true;
      preservation.preserveAt."${persistBase}" = {
        directories = [
          "/var/lib/nixos"
          "/var/lib/sddm"
          "/var/lib/dms-greeter"
          "/var/lib/systemd"
          "/var/lib/NetworkManager"
          "/var/lib/9router"
          "/etc/NetworkManager/system-connections"
          "/var/lib/bluetooth"
          "/var/lib/waydroid"
          "/var/lib/cloudflare-warp"
          {
            directory = "/var/lib/private/wireproxy-warp";
            mode = "0700";
          }
          "/root"
          "/var/lib/libvirt"
          {
            directory = "/var/lib/vnstat";
            user = "vnstatd";
            group = "vnstatd";
            mode = "0755";
          }
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

        users.${config.my.user.name} = {
          directories = [
            "Desktop"
            "xanylabeling_data"
            ".xanylabelingrc"
            ".BurpSuite"
            ".agents"
            ".telegram-mcp"
            ".thunderbird"
            ".config"
            ".java"
            ".tdl"
            ".local/share"
            ".local/state"
            ".steam"
            ".cache/nix"
            ".cache/fish"
            ".cache/DankMaterialShell"
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
            ".antigravity-ide"
            ".gemini"
            {
              directory = ".mcp-colab";
              mode = "0700";
            }
            ".npm"
            "nixos-config"
            "nix-custompkgs"
            "nix-custompkg-priv"
            "nix-mcp"
            "pentest"
          ];
          files = [
            "link.txt"
            ".bash_history"
          ];
        };
      };
      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    };
}
