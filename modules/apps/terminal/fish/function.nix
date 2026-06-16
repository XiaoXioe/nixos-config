{ ... }: {
  programs.fish.functions = {
    "," = {
      body = ''
        if not set -q argv[1]
            echo "Usage: , <package> [args...]"
            return 1
        end
        nix run "nixpkgs#$argv[1]" -- $argv[2..-1]
      '';
    };

    ",," = {
      body = ''
        if not set -q argv[1]
            echo "Usage: ,, <packages...>"
            return 1
        end
        nix shell "nixpkgs#"$argv
      '';
    };
  };
}
