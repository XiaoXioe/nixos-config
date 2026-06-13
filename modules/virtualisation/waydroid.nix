{
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.waydroid";

  nixosConfig =
    {
      virtualisation.waydroid.package = pkgs.waydroid-nftables;

      environment.systemPackages = with pkgs; [
        bindfs
        wl-clipboard
      ];
      boot.supportedFilesystems = [ "fuse" ];

      systemd.tmpfiles.rules = [
        "d /home/klein-moretti/WaydroidShare 0755 klein-moretti users -"
        "d /mnt/data_btrfs/waydroid_data 0755 klein-moretti users -"
        "z /mnt/data_btrfs/waydroid_data 0755 klein-moretti users -"
        "d /mnt/data_btrfs/waydroid_data/klein-moretti 0755 klein-moretti users -"
        "z /mnt/data_btrfs/waydroid_data/klein-moretti 0755 klein-moretti users -"
      ];

      virtualisation.waydroid.enable = true;
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

      fileSystems = lib.mkMerge [
        {
          "/home/klein-moretti/WaydroidShare" = {
            device = "/persist/home/klein-moretti/.local/share/waydroid/data/media/0/Download";
            fsType = "fuse.bindfs";
            options = [
              "nofail"
              "force-user=klein-moretti"
              "force-group=users"
              "create-for-user=1023"
              "create-for-group=1023"
              "chown-ignore"
              "chgrp-ignore"
              "allow_other"
            ];
          };
          "/persist/home/klein-moretti/.local/share/waydroid" = {
            device = "/mnt/data_btrfs/waydroid_data/klein-moretti";
            fsType = "none";
            options = [
              "bind"
              "nofail"
            ];
          };
        }
        {
          "/var/lib/waydroid/images" = {
            device = "/mnt/data_btrfs/waydroid_images/images13";
            fsType = "none";
            options = [ "bind" ];
          };
        }
      ];
    };
}
