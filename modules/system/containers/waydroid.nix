{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.waydroid;
  waydroidUsers = config.my.users;
in
{
  options.my.system.waydroid = {
    enable = selfLib.mkBoolOpt false "Waydroid settings";
  };
  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.package = pkgs.waydroid-nftables;

    environment.systemPackages = with pkgs; [
      bindfs
    ];
    boot.supportedFilesystems = [ "fuse" ];

    # Membuat direktori share secara otomatis
    systemd.tmpfiles.rules = selfLib.forAllUsers waydroidUsers (
      userName: _: [
        "d /home/${userName}/WaydroidShare 0755 ${userName} users -"
        "d /mnt/data_btrfs/waydroid_data/${userName} 0755 ${userName} users -"
      ]
    );

    virtualisation.waydroid.enable = true;

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # MENCEGAH WAYDROID JALAN OTOMATIS SAAT BOOT
    systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

    # Dinamis: iterasi semua user yang berhak mendapat map Waydroid menggunakan helper forAllUsers
    fileSystems = lib.mkMerge [
      (selfLib.forAllUsers waydroidUsers (
        userName: _: {
          "/home/${userName}/WaydroidShare" = {
            device = "/home/${userName}/.local/share/waydroid/data/media/0/Download";
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
          "/home/${userName}/.local/share/waydroid" = {
            device = "/mnt/data_btrfs/waydroid_data/${userName}";
            options = [
              "bind"
              "nofail"
            ];
          };
        }
      ))
      {
        "/var/lib/waydroid/images" = {
          device = "/mnt/data_btrfs/waydroid_images/images11";
          options = [ "bind" ];
        };
      }
    ];
  };
}
