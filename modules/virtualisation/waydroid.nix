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
      "${config.my.dataPath}/waydroid_data"
    ];

    virtualisation.waydroid.package = pkgs.symlinkJoin {
      name = "waydroid-wrapped";
      paths = [ pkgs.waydroid-nftables ];
    };

    environment.systemPackages = with pkgs; [
      bindfs
      wl-clipboard
    ];
    boot.supportedFilesystems = [ "fuse" ];

    virtualisation.waydroid.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

    fileSystems =
      let
        dataPathMount = "${
          lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" config.my.dataPath)
        }.mount";
      in
      lib.mkMerge [
        {
          "/etc/waydroid-extra/images" = {
            device = "${config.my.dataPath}/waydroid_images/images11";
            fsType = "none";
            options = [
              "bind"
              "nofail"
              "x-systemd.requires=${dataPathMount}"
              "x-systemd.after=${dataPathMount}"
              "x-systemd.before=local-fs.target"
            ];
          };
        }
      ];
  };
}
