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

    virtualisation.waydroid.package =
      let
        userName = config.my.user.name;
      in
      pkgs.symlinkJoin {
        name = "waydroid-wrapped";
        paths = [ pkgs.waydroid-nftables ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/waydroid \
            --set XDG_DATA_HOME "${config.my.dataBtrfsPath}/waydroid_data/${userName}/xdg_data"
        '';
      };

    environment.systemPackages = with pkgs; [
      bindfs
      wl-clipboard
    ];
    boot.supportedFilesystems = [ "fuse" ];

    systemd.tmpfiles.rules =
      let
        userName = config.my.user.name;
        dataPath = "${config.my.dataBtrfsPath}/waydroid_data/${userName}/xdg_data";
      in
      [
        "d /home/${userName}/WaydroidShare 0755 ${userName} users -"
        "d ${config.my.dataBtrfsPath}/waydroid_data 0755 ${userName} users -"
        "z ${config.my.dataBtrfsPath}/waydroid_data 0755 ${userName} users -"
        "d ${config.my.dataBtrfsPath}/waydroid_data/${userName} 0755 ${userName} users -"
        "z ${config.my.dataBtrfsPath}/waydroid_data/${userName} 0755 ${userName} users -"
        "d ${dataPath} 0755 ${userName} users -"
        "d ${dataPath}/waydroid 0755 ${userName} users -"
        "d ${dataPath}/waydroid/data 0755 ${userName} users -"
        "d ${dataPath}/waydroid/data/media 0755 ${userName} users -"
        "d ${dataPath}/waydroid/data/media/0 0755 ${userName} users -"
        "d ${dataPath}/waydroid/data/media/0/Download 0755 ${userName} users -"
        "z ${dataPath} 0755 ${userName} users -"
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
            device = "${config.my.dataBtrfsPath}/waydroid_data/${userName}/xdg_data/waydroid/data/media/0/Download";
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
        }
        {
          "/etc/waydroid-extra/images" = {
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
