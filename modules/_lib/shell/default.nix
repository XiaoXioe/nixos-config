# Shell app builders: isolated shell applications and shell completion generators.
{ lib, pkgs }:

{
  # Generates isolated Shell Applications with clean runtimeInputs
  mkApp =
    name: text: runtimeInputs:
    let
      drv = pkgs.writeShellApplication {
        inherit name text runtimeInputs;
        excludeShellChecks = [
          "SC2012"
        ];
      };
    in
    drv
    // {
      __toString = self: "${drv}/bin/${name}";
    };

  # Generate xdg.configFile completions for multiple shells
  # Usage: mkShellCompletions { name = "mycmd"; bash = "..."; fish = "..."; zsh = "..."; }
  mkShellCompletions =
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
}
