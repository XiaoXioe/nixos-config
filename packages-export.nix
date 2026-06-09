{
  nixosConfigs,
  homeConfigs,
  hostName,
  adminUser,
}:

{
  # Menarik dari Home Manager
  dank-shell = homeConfigs."${adminUser}@${hostName}".config.programs.dank-material-shell.package;
  ayugram = homeConfigs."${adminUser}@${hostName}".config.my.user.custompkgs.ayugramPackage;

  # Menarik dari NixOS
  llama = nixosConfigs.${hostName}.config.my.system.ai.llama.package;
}
