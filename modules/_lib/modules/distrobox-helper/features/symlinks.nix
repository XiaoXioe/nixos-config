{ lib }:

{
  options = {
    symlinks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
      default = { };
      description = "A mapping of target path in the container to source path on host (or shared location).";
      example = {
        "/etc/localtime" = "/var/host/etc/localtime";
      };
    };
  };

  # Menghasilkan init_hooks untuk membuat symlink file deklaratif di dalam container
  mkInitHooks =
    cVal:
    let
      links = cVal.symlinks or { };
    in
    lib.mapAttrsToList (
      target: source:
      ''sudo mkdir -p "$(dirname ${lib.escapeShellArg target})" && sudo ln -sf ${lib.escapeShellArg source} ${lib.escapeShellArg target}''
    ) links;
}
