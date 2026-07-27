{
  config,
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.libvirt";
  description = "Libvirt virtualisation daemon, virt-manager, and QEMU hypervisor";

  nixosConfig = {
    users.users.${config.my.user.name}.extraGroups = [ "libvirtd" ];

    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      qemu
    ];

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
