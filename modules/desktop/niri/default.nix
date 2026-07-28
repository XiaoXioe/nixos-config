{
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";
  description = "Niri window manager with DankMaterialShell";

  imports = [
    inputs.niri.nixosModules.niri
    ./dms
  ];

  nixosConfig =
    { pkgs, ... }:
    {
      programs.niri.enable = true;
      programs.niri.package = pkgs.niri;
    };

  hmConfig = hmOpts: {
    imports = [
      ./settings
    ];
  };
}
