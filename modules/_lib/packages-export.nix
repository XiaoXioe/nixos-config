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
  system = pkgs.stdenv.hostPlatform.system;
in
# ==========================================================================
# SINGLE SOURCE OF TRUTH untuk CI build targets.
# Tambah/hapus atribut di sini → GitHub Actions & Kaggle builder otomatis
# mengikuti via: nix eval .#packages.x86_64-linux --apply builtins.attrNames
# ==========================================================================
{
  # Menarik dari NixOS — sengaja TANPA fallback: jika opsi hilang karena
  # refactor, eval harus gagal keras alih-alih diam-diam meng-cache pkgs.hello.
  llama-cpp = config.my.ai.runtimes.llama.package;

  # Torlink package
  torlink = inputs.torlink.packages.${system}.default;

  # DankMaterialShell package (agar di-cache oleh CI)
  dms = inputs.dms.packages.${system}.default;
}
# Caelestia hanya diekspor bila modulnya benar-benar aktif (butuh input
# caelestia-shell yang saat ini tidak ada di flake.nix).
// pkgs.lib.optionalAttrs (userConfig.programs ? caelestia) {
  caelestia = userConfig.programs.caelestia.package;
}
