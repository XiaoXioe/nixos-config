{
  nixosConfigs,
  homeConfigs,
  hostName,
  adminUser,
}:

{
  # Menarik dari Home Manager via NixOS config
  dank-shell =
    nixosConfigs.${hostName}.config.home-manager.users.${adminUser}.programs.dank-material-shell.package;

  caelestia =
    nixosConfigs.${hostName}.config.home-manager.users.${adminUser}.programs.caelestia.package;

  # Menarik dari NixOS
  llama = nixosConfigs.${hostName}.config.my.ai.llama.package;
}
