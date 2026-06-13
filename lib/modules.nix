{ lib, ... }:

{
  # Unified module builder for NixOS and Home Manager.
  # Automatically creates 'options.my.${name}.enable'.
  # Merges nixosConfig and hmConfig under an 'mkIf' guard.
  mkModule =
    {
      name,
      description ? "",
      options ? { },
      nixosConfig ? { },
      hmConfig ? { },
    }:
    {
      imports = [
        ({ config, lib, ... }:
          let
            optionPath = lib.splitString "." name;
            cfg = lib.getAttrFromPath (optionPath ++ [ "enable" ]) config.my;
          in
          {
            options.my = lib.setAttrByPath optionPath (
              {
                enable = lib.mkEnableOption (if description != "" then description else name);
              } // options
            );

            config = lib.mkIf cfg (lib.mkMerge [
              nixosConfig
              (lib.mkIf (hmConfig != { }) {
                home-manager.users.${config.my.user.name} = hmConfig;
              })
            ]);
          }
        )
      ];
    };
}
