{
  nixosConfigs,
  hostName,
  adminUser,
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
}
