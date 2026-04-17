{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.rollback;
in
{
  options.my.system.rollback = {
    device = selfLib.mkOpt lib.types.str "" "The UUID of the BTRFS device to rollback";
  };

  config = lib.mkIf config.my.system.impermanence.enable {
    boot.initrd.supportedFilesystems = [ "btrfs" ];
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvol=/ ${cfg.device} /btrfs_tmp

      if [ -e /btrfs_tmp/@nixos-root ]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@nixos-root)" "+%Y-%m-%d_%H:%M:%S")
          mv /btrfs_tmp/@nixos-root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      echo "Restore root kosong..."
      btrfs subvolume snapshot /btrfs_tmp/@nixos-root-blank /btrfs_tmp/@nixos-root

      umount /btrfs_tmp
    '';
  };
}
