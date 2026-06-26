{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";
  description = "Niri window manager with DankMaterialShell";

  imports = [
    ./dms.nix
  ];

  nixosConfig = {
    programs.niri.enable = true;
  };

  hmConfig = hmOpts: {
    imports = [
      ./settings.nix
    ];
  };
}
