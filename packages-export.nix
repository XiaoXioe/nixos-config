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
  # Menarik dari Home Manager via NixOS config
  dank-shell = userConfig.programs.dank-material-shell.package or pkgs.hello;

  caelestia = userConfig.programs.caelestia.package or pkgs.hello;

  # Menarik dari NixOS
  llama = config.my.ai.llama.package or pkgs.hello;

  # Input eksternal non-cached (quickshell)
  quickshell = inputs.dms.packages.${pkgs.system}.quickshell;

  # Pipewire 32-bit (dengan kustom overlay agar di-cache oleh CI)
  pipewire-32bit = pkgs.pkgsi686Linux.pipewire;
}
