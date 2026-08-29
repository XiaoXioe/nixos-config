{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  custom = inputs.custompkgs.packages.${system};
  priv = inputs.custompkgs-priv.packages.${system};
in
selfLib.mkModule {
  name = "apps.custom.scrapers";
  description = "Custom streaming and media scraping tools";

  hmConfig = {
    home.packages = [
      custom.streambert
      priv.burpsuitepro
      priv.anichin-scraper
      priv.lk21-scraper
    ];
  };
}
