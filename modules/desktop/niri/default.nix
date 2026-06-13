{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";
  description = "Niri window manager with DankMaterialShell";

  nixosConfig = {
    # System-level dependencies for Niri
    environment.systemPackages = with pkgs; [
      nautilus
      kdePackages.gwenview
    ];

    programs.niri.enable = true;
  };

  hmConfig = {
    imports = [
      ./settings.nix
      ./dms.nix
    ];
  };
}
