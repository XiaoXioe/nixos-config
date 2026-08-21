{ lib }:

let
  strOrListOfStr = lib.types.coercedTo lib.types.str (s: if s == "" then [ ] else [ s ]) (
    lib.types.listOf lib.types.str
  );
in
{
  options = {
    copr = lib.mkOption {
      type = strOrListOfStr;
      default = [ ];
      description = "List of Fedora COPR repositories to enable (e.g. ['atim/starship']).";
    };
  };

  # Menghasilkan pre_init_hooks untuk meng-enable repositori COPR sebelum dnf dijalankan
  mkPreInitHooks =
    cVal:
    let
      repos = cVal.copr or [ ];
    in
    map (repo: "sudo dnf copr enable -y ${lib.escapeShellArg repo}") repos;
}
