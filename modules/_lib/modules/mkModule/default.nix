_:

# Unified module builder for NixOS and Home Manager.
# Automatically creates 'options.my.${name}.enable' for global NixOS state.
{
  name,
  description ? "",
  options ? { },
  imports ? [ ],
  nixosConfig ? { },
  hmConfig ? null,
  preservation ? { },
}:
# Validasi nama modul: harus dimulai huruf, hanya boleh alphanum/dots/dashes/underscores.
# Mencegah typo diam-diam (spasi, slash, karakter aneh) yang menghasilkan option path orphan.
assert
  builtins.match "[a-zA-Z][a-zA-Z0-9._-]*" name != null
  || builtins.throw "mkModule: invalid name '${name}'. Must match [a-zA-Z][a-zA-Z0-9._-]*.";
{
  imports = imports ++ [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        optionPath = lib.splitString "." name;
        cfg = lib.getAttrFromPath (optionPath ++ [ "enable" ]) config.my;

        resolvedNixosConfig =
          if builtins.isFunction nixosConfig then nixosConfig { inherit config lib pkgs; } else nixosConfig;

        # Preservation schema type — extracted to standalone file for maintainability
        preservationAspectType = import ./preservation-schema.nix { inherit lib; };
      in
      {
        options.my =
          lib.recursiveUpdate
            (lib.optionalAttrs (name == "hardware.preservation") {
              preservation.aspects = lib.mkOption {
                type = lib.types.attrsOf preservationAspectType;
                default = { };
                description = "Co-located preservation rules registered by modules.";
              };
            })
            (
              lib.setAttrByPath optionPath (
                let
                  baseOptions = {
                    enable = lib.mkEnableOption (if description != "" then description else name);
                  };
                in
                baseOptions // options
              )
            );

        config = lib.mkMerge [
          (lib.mkIf (preservation != { }) {
            my.preservation.aspects."${name}" = {
              enable = cfg;
              rule = preservation;
            };
          })
          (lib.mkIf cfg (
            let
              hasUser = config.my ? user && config.my.user ? name;
              userName = if hasUser then config.my.user.name else null;
            in
            lib.mkMerge [
              resolvedNixosConfig
              (lib.mkIf (hmConfig != null && userName != null) {
                home-manager.users.${userName} = if builtins.isFunction hmConfig then hmConfig else (_: hmConfig);
              })
            ]
          ))
        ];
      }
    )
  ];
}
