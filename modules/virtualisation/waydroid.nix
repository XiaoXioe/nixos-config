{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.waydroid";

  preservation = {
    persist = true;
    directories = [ "/var/lib/waydroid" ];
  };

  nixosConfig = {
    my.services.storage.btrfs-nocow-migration.nocowDirectories = [
      "${config.my.dataBtrfsPath}/waydroid_data"
    ];

    virtualisation.waydroid.package = pkgs.waydroid-nftables;

    environment.systemPackages = with pkgs; [
      bindfs
      wl-clipboard
    ];
    boot.supportedFilesystems = [ "fuse" ];

    systemd.tmpfiles.rules =
      let
        userName = config.my.user.name;
      in
      [
        "d /home/${userName}/WaydroidShare 0755 ${userName} users -"
        "d /persist/home/${userName}/.local/share/waydroid/data/media/0/Download 0755 ${userName} users -"
        "d ${config.my.dataBtrfsPath}/waydroid_data 0755 ${userName} users -"
        "z ${config.my.dataBtrfsPath}/waydroid_data 0755 ${userName} users -"
        "d ${config.my.dataBtrfsPath}/waydroid_data/${userName} 0755 ${userName} users -"
        "z ${config.my.dataBtrfsPath}/waydroid_data/${userName} 0755 ${userName} users -"
      ];

    virtualisation.waydroid.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

    fileSystems =
      let
        userName = config.my.user.name;
      in
      lib.mkMerge [
        {
          "/home/${userName}/WaydroidShare" = {
            device = "/persist/home/${userName}/.local/share/waydroid/data/media/0/Download";
            fsType = "fuse.bindfs";
            options = [
              "nofail"
              "force-user=${userName}"
              "force-group=users"
              "create-for-user=1023"
              "create-for-group=1023"
              "chown-ignore"
              "chgrp-ignore"
              "allow_other"
            ];
          };
          "/persist/home/${userName}/.local/share/waydroid" = {
            device = "${config.my.dataBtrfsPath}/waydroid_data/${userName}";
            fsType = "none";
            options = [
              "bind"
              "nofail"
            ];
          };
        }
        {
          "/var/lib/waydroid/images" = {
            device = "${config.my.dataBtrfsPath}/waydroid_images/halcyon-os";
            fsType = "none";
            options = [
              "bind"
              "nofail"
            ];
          };
        }
      ];
  };
}
