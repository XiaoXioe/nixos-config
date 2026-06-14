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
  dank-shell =
    if userConfig.programs ? dank-material-shell then
      userConfig.programs.dank-material-shell.package
    else
      pkgs.hello;

  caelestia =
    if userConfig.programs ? caelestia then
      userConfig.programs.caelestia.package
    else
      pkgs.hello;

  # Menarik dari NixOS
  llama =
    if config.my ? ai && config.my.ai ? llama then
      config.my.ai.llama.package
    else
      pkgs.hello;
}
