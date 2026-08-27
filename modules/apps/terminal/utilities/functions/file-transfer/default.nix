{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  tools = [
    "ambil"
    "kirim"
  ];

  mkToolPkg =
    name:
    pkgs.writers.writePython3Bin name { flakeIgnore = [ "E501" ]; } (
      builtins.readFile (./scripts + "/${name}.py")
    );

  mkCompletion =
    name:
    selfLib.mkShellCompletions pkgs {
      inherit name;
      fish = ''
        complete -c ${name} -a "(grep '^Host ' ~/.ssh/config | awk '{print \$2}')"
      '';
      bash = ''
        _${name}() {
          local cur="''${COMP_WORDS[COMP_CWORD]}"
          hosts=$(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}')
          COMPREPLY=( $(compgen -W "$hosts" -- "$cur") )
        }
        complete -F _${name} ${name}
      '';
      zsh = ''
        _${name}() {
          local hosts
          hosts=($(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}'))
          compadd -a hosts
        }
        compdef _${name} ${name}
      '';
    };
in
selfLib.mkModule {
  name = "apps.terminal.utilities.functions.file-transfer";
  description = "File transfer scripts (ambil & kirim)";

  hmConfig = {
    home.packages = map mkToolPkg tools;

    xdg.configFile = lib.mkMerge (map mkCompletion tools);

    programs.zsh.initExtra = ''
      fpath+=($HOME/.config/zsh/completions)
    '';
  };
}
