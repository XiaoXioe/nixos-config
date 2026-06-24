{
  nixosConfigs,
  hostName,
  adminUser,
  inputs,
}:
let
  userConfig = nixosConfigs.${hostName}.config.home-manager.users.${adminUser};
  pkgs = nixosConfigs.${hostName}.pkgs;
  config = nixosConfigs.${hostName}.config;
in
{
  caelestia = userConfig.programs.caelestia.package or pkgs.hello;

  # Menarik dari NixOS
  llama = config.my.ai.llama.package or pkgs.hello;

  # Pipewire 32-bit (dengan kustom overlay agar di-cache oleh CI)
  pipewire-32bit = pkgs.pkgsi686Linux.pipewire;

  # Pipewire 64-bit host system (agar di-cache oleh CI)
  pipewire = pkgs.pipewire;
}
