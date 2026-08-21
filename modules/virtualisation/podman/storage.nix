{
  config,
  lib,
  ...
}:

{
  # Btrfs NoCoW persistence for Podman container layers
  my.services.storage.btrfs-nocow-migration.nocowDirectories = [
    "${config.my.dataPath}/podman"
  ];

  # Native Podman virtualisation daemon
  virtualisation.podman = {
    enable = true;
    dockerCompat = lib.mkDefault true;
  };

  # Dedicated tmpfiles persistence rules for Podman storage layout
  systemd.tmpfiles.rules = [
    "d ${config.my.dataPath}/podman 0755 ${config.my.user.name} users - -"
    "d ${config.my.dataPath}/podman/containers 0755 ${config.my.user.name} users - -"
    "d /home/${config.my.user.name}/.local 0755 ${config.my.user.name} users - -"
    "d /home/${config.my.user.name}/.local/share 0755 ${config.my.user.name} users - -"
    "L+ /home/${config.my.user.name}/.local/share/containers - - - - ${config.my.dataPath}/podman/containers"
  ];
}
