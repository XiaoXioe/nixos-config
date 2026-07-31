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

  # Generate a list of shell script packages from an attribute set
  # Usage: mkScripts { "script-name" = "echo hello"; }
  mkScripts =
    scriptsAttrSet:
    lib.mapAttrsToList (
      name: script:
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [ pkgs.coreutils ];
        text = script;
      }
    ) scriptsAttrSet;

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
