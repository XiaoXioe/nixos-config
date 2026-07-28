{ lib, pkgs }:

{
  # Generate a list of shell script packages from an attribute set
  # Usage: mkScripts { "script-name" = "echo hello"; }
  mkScripts =
    scriptsAttrSet:
    lib.mapAttrsToList (name: script: pkgs.writeShellScriptBin name script) scriptsAttrSet;

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
