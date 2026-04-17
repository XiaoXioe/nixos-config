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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # --- Custompkgs Publik ---
      # custom.freqtrade
      custom.uabea
      custom.vimmdl
      custom.disbox
      custom.binance

      # --- Paket dari Private Repo ---
      priv.anichin-scraper
      priv.lk21-scraper
      priv.burpsuitepro
    ];
  };
}
