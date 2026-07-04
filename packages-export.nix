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
  # Menarik dari NixOS — sengaja TANPA fallback: jika opsi hilang karena
  # refactor, eval harus gagal keras alih-alih diam-diam meng-cache pkgs.hello.
  llama = config.my.ai.llama.package;

  # Pipewire 32-bit (dengan kustom overlay agar di-cache oleh CI)
  pipewire-32bit = pkgs.pkgsi686Linux.pipewire;

  # Pipewire 64-bit host system (agar di-cache oleh CI)
  pipewire = pkgs.pipewire;
}
# Caelestia hanya diekspor bila modulnya benar-benar aktif (butuh input
# caelestia-shell yang saat ini tidak ada di flake.nix).
// pkgs.lib.optionalAttrs (userConfig.programs ? caelestia) {
  caelestia = userConfig.programs.caelestia.package;
}
