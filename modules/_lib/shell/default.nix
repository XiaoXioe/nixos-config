# Shell app builders: isolated shell applications and shell completion generators.
{ lib, ... }:

{
  # Generates isolated Shell Applications with clean runtimeInputs
  # Usage: selfLib.mkApp pkgs "name" "script-text" [ runtimeInputs ]
  mkApp =
    pkgs: name: text: runtimeInputs:
    let
      drv = pkgs.writeShellApplication {
        inherit name text runtimeInputs;
        excludeShellChecks = [
          "SC2012"
          "SC2016"
        ];
      };
    in
    drv
    // {
      __toString = _: "${drv}/bin/${name}";
    };

  # Generate xdg.configFile completions for multiple shells
  # Supports both direct call: selfLib.mkShellCompletions { name = "..."; ... }
  # and curried call: (selfLib.mkShellCompletions pkgs) { name = "..."; ... }
  mkShellCompletions =
    arg1:
    let
      impl =
        {
          name,
          fish ? "",
          bash ? "",
          zsh ? "",
        }:
        (lib.optionalAttrs (fish != "") {
          "fish/completions/${name}.fish".text = fish;
        })
        // (lib.optionalAttrs (bash != "") {
          "bash/completions/${name}".text = bash;
        })
        // (lib.optionalAttrs (zsh != "") {
          "zsh/completions/_${name}".text = zsh;
        });
    in
    if builtins.isAttrs arg1 && !(arg1 ? name) then
      # arg1 is pkgs instance (legacy / curried caller)
      impl
    else
      # arg1 is option attrset directly
      impl arg1;
}
