{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.waydroid";

  nixosConfig =
    let
      waydroidUsers = config.my.users;
    in
    {
      virtualisation.waydroid.package = pkgs.waydroid-nftables;

      environment.systemPackages = with pkgs; [
        bindfs
        wl-clipboard
      ];
      boot.supportedFilesystems = [ "fuse" ];

      systemd.tmpfiles.rules = selfLib.forAllUsers waydroidUsers (
        userName: _: [
          "d /home/${userName}/WaydroidShare 0755 ${userName} users -"
          "d /mnt/data_btrfs/waydroid_data 0755 ${userName} users -"
          "z /mnt/data_btrfs/waydroid_data 0755 ${userName} users -"
          "d /mnt/data_btrfs/waydroid_data/${userName} 0755 ${userName} users -"
          "z /mnt/data_btrfs/waydroid_data/${userName} 0755 ${userName} users -"
        ]
      );

      virtualisation.waydroid.enable = true;
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

      fileSystems = lib.mkMerge [
        (selfLib.forAllUsers waydroidUsers (
          userName: _: {
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
              device = "/mnt/data_btrfs/waydroid_data/${userName}";
              fsType = "none";
              options = [
                "bind"
                "nofail"
              ];
            };
          }
        ))
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
