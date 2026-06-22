{
  config,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.libvirt";

  nixosConfig = {
    users.users.${config.my.user.name}.extraGroups = [ "libvirtd" ];

    programs.virt-manager.enable = true;

    systemd.services.libvirtd.serviceConfig = {
      TimeoutStopSec = "5s";
      TimeoutStartSec = "5s";
    };

    systemd.services.libvirt-guests.enable = false;

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
    };
  };
}
