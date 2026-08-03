{
  pkgs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.functions.file-transfer";
  description = "File transfer scripts (ambil & kirim)";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writers.writePython3Bin "ambil" { flakeIgnore = [ "E501" ]; } (
        builtins.readFile ./scripts/ambil.py
      ))
      (pkgs.writers.writePython3Bin "kirim" { flakeIgnore = [ "E501" ]; } (
        builtins.readFile ./scripts/kirim.py
      ))
    ];

    # Integrasi autocompletion langsung ke konfigurasi Shell di Home Manager
    xdg.configFile = lib.mkMerge [
      (selfLib.mkShellCompletions pkgs {
        name = "ambil";
        fish = ''
          complete -c ambil -a "(grep '^Host ' ~/.ssh/config | awk '{print \$2}')"
        '';
        bash = ''
          _ambil() {
            local cur="''${COMP_WORDS[COMP_CWORD]}"
            hosts=$(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}')
            COMPREPLY=( $(compgen -W "$hosts" -- "$cur") )
          }
          complete -F _ambil ambil
        '';
        zsh = ''
          _ambil() {
            local hosts
            hosts=($(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}'))
            compadd -a hosts
          }
          compdef _ambil ambil
        '';
      })
      (selfLib.mkShellCompletions pkgs {
        name = "kirim";
        fish = ''
          complete -c kirim -a "(grep '^Host ' ~/.ssh/config | awk '{print \$2}')"
        '';
        bash = ''
          _kirim() {
            local cur="''${COMP_WORDS[COMP_CWORD]}"
            hosts=$(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}')
            COMPREPLY=( $(compgen -W "$hosts" -- "$cur") )
          }
          complete -F _kirim kirim
        '';
        zsh = ''
          _kirim() {
            local hosts
            hosts=($(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}'))
            _describe 'hosts' hosts
          }
        '';
      })
    ];

    programs.zsh.initExtra = ''
      fpath+=($HOME/.config/zsh/completions)
    '';
  };
}
