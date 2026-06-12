{
  config,
  lib,
  selfLib,
  allUsers,
  ...
}:
let
  cfg = config.my.hardware.preservation;
  persistBase = "/persist";

  btrfsDevice = "/dev/disk/by-uuid/f888825f-bdb2-4dca-9c58-b5dd4f6a39d8";
  rootSubvol = "@nixos-root";
  homeSubvol = "@nixos-home";

  wipeRootScript = ''
    echo "==> [preservation] Wiping ephemeral root and home subvolumes..."
    mkdir -p /btrfs_tmp
    mount -t btrfs -o subvol=/ ${btrfsDevice} /btrfs_tmp
    timestamp=$(date "+%Y-%m-%d_%H:%M:%S")
    mkdir -p /btrfs_tmp/@nixos-old-roots
    if [[ -e /btrfs_tmp/${rootSubvol} ]]; then
      mv /btrfs_tmp/${rootSubvol} "/btrfs_tmp/@nixos-old-roots/root-$timestamp"
    fi
    btrfs subvolume create /btrfs_tmp/${rootSubvol}
    if [[ -e /btrfs_tmp/${homeSubvol} ]] && [[ -e /btrfs_tmp/@nixos-persist ]]; then
      mkdir -p /btrfs_tmp/@nixos-persist/home-snapshots
      btrfs subvolume snapshot -r /btrfs_tmp/${homeSubvol} "/btrfs_tmp/@nixos-persist/home-snapshots/$timestamp"
      old_snaps=$(ls -1dt /btrfs_tmp/@nixos-persist/home-snapshots/* 2>/dev/null | tail -n +11)
      for snap in $old_snaps; do
        btrfs subvolume delete "$snap"
      done
    fi
    if [[ -e /btrfs_tmp/${homeSubvol} ]]; then
      mv /btrfs_tmp/${homeSubvol} "/btrfs_tmp/@nixos-old-roots/home-$timestamp"
    fi
    btrfs subvolume create /btrfs_tmp/${homeSubvol}
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
        delete_subvolume_recursively "$i"
      done
    }
    cleanup_old_backups "root"
    cleanup_old_backups "home"
    umount /btrfs_tmp
  '';
in
{
  options = selfLib.mkNestedEnable "hardware.preservation" // {
    ephemeralRoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to wipe the root subvolume on every boot.";
    };
    extraDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
    };
    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
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
        { directory = "/var/lib/private/ollama"; mode = "0700"; }
        { directory = "/var/lib/private/open-webui"; mode = "0700"; }
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ] ++ cfg.extraDirectories;

      files = [
        { file = "/etc/machine-id"; inInitrd = true; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_ed25519_key.pub"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_rsa_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_rsa_key.pub"; how = "symlink"; configureParent = true; }
      ] ++ cfg.extraFiles;

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
          { directory = ".ssh"; mode = "0700"; }
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".android"; mode = "0700"; }
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
