{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";

  nixosConfig = {
    environment.systemPackages = with pkgs; [
      nautilus
      kdePackages.gwenview
    ];

    programs.niri.enable = true;
  };
}
