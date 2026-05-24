{
  config,
  pkgs,
  lib,
  selfLib,
  inputs,
  ...
}:
let
  cfg = config.my.user.custompkgs;

  system = pkgs.stdenv.hostPlatform.system;
  custom = inputs.custompkgs.packages.${system};
  priv = inputs.custompkgs-priv.packages.${system};
in
{
  options.my.user.custompkgs = {
    enable = selfLib.mkBoolOpt false "Custom packages";

    # Daftarkan paket di sini agar bisa dipanggil spesifik oleh GitHub Action
    ayugramPackage = lib.mkOption {
      type = lib.types.package;
      default = priv.ayugram-desktop;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # --- Custompkgs Publik ---
      custom.vimmdl
      custom.disbox
      custom.binance
      custom.streambert

      # --- Paket dari Private Repo ---
      priv.anichin-scraper
      priv.lk21-scraper
      priv.burpsuitepro
      cfg.ayugramPackage
      # priv.titan-agent
    ];
  };
}
