{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.office.protonmail";
  description = "Proton Mail desktop application wrapper (PWA)";

  hmConfig = {
    home.packages = [
      (selfLib.mkWebApp pkgs {
        name = "proton-mail";
        desktopName = "Proton Mail";
        url = "https://mail.proton.me";
        icon = pkgs.fetchurl {
          url = "https://www.vectorlogo.zone/logos/protonmail/protonmail-icon.svg";
          sha256 = "08xzlagk520z7l3zxhxiy55cikh122433f75hh2l9r4xffkl081r";
        };
        comment = "Proton Mail client via Chromium/Brave App Mode";
        browser = "brave";
        wmClass = "mail.proton.me";
      })
    ];
  };
}
