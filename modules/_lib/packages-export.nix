{
  nixosConfigs,
  hostName,
  adminUser,
  inputs,
  selfLib ? null,
}:
let
  userConfig = nixosConfigs.${hostName}.config.home-manager.users.${adminUser};
  pkgs = nixosConfigs.${hostName}.pkgs;
  config = nixosConfigs.${hostName}.config;
in
{
  # Menarik dari NixOS — sengaja TANPA fallback: jika opsi hilang karena
  # refactor, eval harus gagal keras alih-alih diam-diam meng-cache pkgs.hello.
  llama = config.my.ai.runtimes.llama.package;

  # Torlink package
  torlink = inputs.torlink.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # DankMaterialShell package (agar di-cache oleh CI)
  dms = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;

}
# Caelestia hanya diekspor bila modulnya benar-benar aktif (butuh input
# caelestia-shell yang saat ini tidak ada di flake.nix).
// pkgs.lib.optionalAttrs (userConfig.programs ? caelestia) {
  caelestia = userConfig.programs.caelestia.package;
}
